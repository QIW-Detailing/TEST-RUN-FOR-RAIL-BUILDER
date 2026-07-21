$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:8084/")
$listener.Start()
Write-Host "Test server started on http://localhost:8084/"

$debugLog = "debug.log"
Clear-Content -Path $debugLog -ErrorAction SilentlyContinue

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $url = $request.Url.LocalPath
        if ($url -eq "/save-zip") {
            $reader = New-Object System.IO.StreamReader($request.InputStream)
            $base64 = $reader.ReadToEnd()
            $bytes = [System.Convert]::FromBase64String($base64)
            [System.IO.File]::WriteAllBytes("test_output.zip", $bytes)
            
            $buf = [System.Text.Encoding]::UTF8.GetBytes("ZIP saved successfully")
            $response.ContentLength64 = $buf.Length
            $response.OutputStream.Write($buf, 0, $buf.Length)
            $response.Close()
            Write-Host "ZIP saved successfully to test_output.zip"
        }
        elseif ($url -eq "/log") {
            $msg = $request.QueryString["msg"]
            Write-Host "LOG: $msg"
            Add-Content -Path $debugLog -Value $msg
            
            $buf = [System.Text.Encoding]::UTF8.GetBytes("Log received")
            $response.ContentLength64 = $buf.Length
            $response.OutputStream.Write($buf, 0, $buf.Length)
            $response.Close()
        }
        else {
            $filePath = Join-Path (Get-Location) $url.TrimStart('/')
            if ($url -eq "/") {
                $filePath = Join-Path (Get-Location) "test.html"
            }
            
            if (Test-Path $filePath -PathType Leaf) {
                $bytes = [System.IO.File]::ReadAllBytes($filePath)
                $response.ContentLength64 = $bytes.Length
                
                if ($filePath.EndsWith(".js")) {
                    $response.ContentType = "application/javascript"
                } elseif ($filePath.EndsWith(".html")) {
                    $response.ContentType = "text/html"
                } elseif ($filePath.EndsWith(".css")) {
                    $response.ContentType = "text/css"
                }
                
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            } else {
                $response.StatusCode = 404
            }
            $response.Close()
        }
    } catch {
        Write-Host "Error: $_"
    }
}
