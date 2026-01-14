import type { NextApiRequest, NextApiResponse } from 'next'

const GATEWAY_URL = 'http://localhost:3001'

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
  // --- 1. 统一设置 CORS 响应头（对于所有请求） ---
  res.setHeader('Access-Control-Allow-Origin', '*')
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
  // 必须包含所有客户端可能发送的非简单头
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, X-Requested-With, Accept')
  // 可选：设置预检请求缓存时间
  res.setHeader('Access-Control-Max-Age', '86400') 

  // --- 2. 拦截并处理 OPTIONS 预检请求 ---
  if (req.method === 'OPTIONS') {
    // 预检请求成功，直接返回 200/204 状态码
    // 注意：CORS 相关的头已经在上面设置了
    console.log('✅ Gateway Proxy: Handled CORS OPTIONS preflight request.')
    return res.status(204).end() 
  }

  // --- 3. 处理实际的请求 (GET, POST, PUT, DELETE, etc.) ---
  const { path, ...queryParams } = req.query
  const pathString = Array.isArray(path) ? path.join('/') : path

  // Build the target URL
  const targetUrl = `${GATEWAY_URL}/${pathString}`
  
  // Remove 'path' from query params and build query string
  const filteredQuery = Object.fromEntries(
    Object.entries(queryParams).filter(([key]) => key !== 'path')
  )
  const queryString = new URLSearchParams(filteredQuery as Record<string, string>).toString()
  const fullUrl = queryString ? `${targetUrl}?${queryString}` : targetUrl

  console.log('🔧 Gateway Proxy: Proxying request to:', fullUrl)

  try {
    // Forward the request to the actual Gateway
    const response = await fetch(fullUrl, {
      method: req.method,
      headers: {
        // NOTE: 通常 Content-Type 不应该在代理中被硬编码，除非您确定所有转发请求都是 JSON
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // Forward relevant headers
        ...(req.headers.authorization && { 'Authorization': req.headers.authorization as string }),
      },
      // 避免将 GET/HEAD 请求的 body 转发
      body: req.method !== 'GET' && req.method !== 'HEAD' ? JSON.stringify(req.body) : undefined,
    })

    // 检查响应内容类型以决定如何解析
    const contentType = response.headers.get('content-type');
    let data: any;
    if (contentType && contentType.includes('application/json')) {
      data = await response.json();
    } else {
      // 处理非 JSON 响应，例如 text/plain
      data = await response.text();
    }

    console.log('🔧 Gateway Proxy: Response status:', response.status)

    // NOTE: CORS 头已在上方设置，这里只需返回状态和数据
    res.status(response.status).send(data) // 使用 send 或 json 取决于 data 的类型

  } catch (error) {
    console.error('🔧 Gateway Proxy: Error:', error)
    res.status(500).json({ error: 'Proxy error', details: (error as Error).message })
  }
}
