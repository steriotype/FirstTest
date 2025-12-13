# Simple PowerShell static file server using HttpListener
param(
    [int]$Port = 8000
)
$prefix = "http://localhost:$Port/"
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($prefix)
$listener.Start()
Write-Host "Serving $PWD at $prefix - press Ctrl+C to stop"
while ($true) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        $urlPath = $request.Url.AbsolutePath.TrimStart('/')
        if ([string]::IsNullOrEmpty($urlPath)) { $urlPath = 'index.html' }
        $localPath = Join-Path $PWD $urlPath
        # Handle registration POST endpoint
        if ($request.HttpMethod -eq 'POST' -and $request.Url.AbsolutePath -eq '/register') {
            try {
                $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
                $body = $reader.ReadToEnd()
                Write-Host "[serve.ps1] POST /register body: $body"
                $reader.Close()
                $obj = ConvertFrom-Json $body
                if (-not $obj.email -or -not $obj.password -or -not $obj.name) {
                    $response.StatusCode = 400
                    $bytes = [System.Text.Encoding]::UTF8.GetBytes('{"error":"Missing fields"}')
                    $response.ContentType = 'application/json'
                    $response.OutputStream.Write($bytes,0,$bytes.Length)
                    $response.Close()
                    continue
                }

                $dbPath = Join-Path $PWD 'users.json'
                if (-not (Test-Path $dbPath)) { Set-Content -Path $dbPath -Value '[]' -Encoding UTF8 }
                $users = Get-Content $dbPath -Raw | ConvertFrom-Json
                if ($users -and ($users | Where-Object { $_.email -ieq $obj.email })) {
                    $response.StatusCode = 409
                    $bytes = [System.Text.Encoding]::UTF8.GetBytes('{"error":"Email already registered"}')
                    $response.ContentType = 'application/json'
                    $response.OutputStream.Write($bytes,0,$bytes.Length)
                    $response.Close()
                    continue
                }

                # Hash password with SHA256
                $sha = [System.Security.Cryptography.SHA256]::Create()
                $pwdBytes = [System.Text.Encoding]::UTF8.GetBytes($obj.password)
                $hashBytes = $sha.ComputeHash($pwdBytes)
                $hashHex = ([System.BitConverter]::ToString($hashBytes)).Replace('-','').ToLower()

                $newUser = @{ name = $obj.name; email = $obj.email; password = $hashHex; created = (Get-Date).ToString('o') }
                $all = @()
                if ($users) { $all = $users }
                $all += $newUser
                $all | ConvertTo-Json -Depth 5 | Set-Content -Path $dbPath -Encoding UTF8

                $response.StatusCode = 201
                $bytes = [System.Text.Encoding]::UTF8.GetBytes('{"ok":true}')
                $response.ContentType = 'application/json'
                $response.OutputStream.Write($bytes,0,$bytes.Length)
                $response.Close()
                continue
            } catch {
                Write-Host "[serve.ps1] POST /register handler error: $_"
                $response.StatusCode = 500
                $bytes = [System.Text.Encoding]::UTF8.GetBytes('{"error":"Server error"}')
                $response.ContentType = 'application/json'
                $response.OutputStream.Write($bytes,0,$bytes.Length)
                $response.Close()
                continue
            }
        }
        # Handle login POST endpoint
        if ($request.HttpMethod -eq 'POST' -and $request.Url.AbsolutePath -eq '/login') {
            try {
                $reader = New-Object System.IO.StreamReader($request.InputStream, $request.ContentEncoding)
                $body = $reader.ReadToEnd()
                Write-Host "[serve.ps1] POST /login body: $body"
                $reader.Close()
                $obj = ConvertFrom-Json $body
                if (-not $obj.username -or -not $obj.password) {
                    $response.StatusCode = 400
                    $bytes = [System.Text.Encoding]::UTF8.GetBytes('{"error":"Missing username or password"}')
                    $response.ContentType = 'application/json'
                    $response.OutputStream.Write($bytes,0,$bytes.Length)
                    $response.Close()
                    continue
                }

                $dbPath = Join-Path $PWD 'users.json'
                if (-not (Test-Path $dbPath)) { Set-Content -Path $dbPath -Value '[]' -Encoding UTF8 }
                $users = Get-Content $dbPath -Raw | ConvertFrom-Json

                # Hash provided password
                $sha = [System.Security.Cryptography.SHA256]::Create()
                $pwdBytes = [System.Text.Encoding]::UTF8.GetBytes($obj.password)
                $hashBytes = $sha.ComputeHash($pwdBytes)
                $hashHex = ([System.BitConverter]::ToString($hashBytes)).Replace('-','').ToLower()

                $found = $null
                if ($users) {
                    $found = $users | Where-Object { ($_.email -ieq $obj.username) -or ($_.name -ieq $obj.username) }
                }
                if ($found -and $found.password -eq $hashHex) {
                    $response.StatusCode = 200
                    $userInfo = @{ ok = $true; user = @{ name = $found.name; email = $found.email } }
                    $json = $userInfo | ConvertTo-Json -Depth 4
                    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
                    $response.ContentType = 'application/json'
                    $response.OutputStream.Write($bytes,0,$bytes.Length)
                    $response.Close()
                    continue
                } else {
                    $response.StatusCode = 401
                    $bytes = [System.Text.Encoding]::UTF8.GetBytes('{"error":"Invalid credentials"}')
                    $response.ContentType = 'application/json'
                    $response.OutputStream.Write($bytes,0,$bytes.Length)
                    $response.Close()
                    continue
                }
            } catch {
                Write-Host "[serve.ps1] POST /login handler error: $_"
                $response.StatusCode = 500
                $bytes = [System.Text.Encoding]::UTF8.GetBytes('{"error":"Server error"}')
                $response.ContentType = 'application/json'
                $response.OutputStream.Write($bytes,0,$bytes.Length)
                $response.Close()
                continue
            }
        }
        if (-not (Test-Path $localPath)) {
            $response.StatusCode = 404
            $buffer = [System.Text.Encoding]::UTF8.GetBytes("404 - Not Found")
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
            continue
        }
        $ext = [IO.Path]::GetExtension($localPath).ToLower()
        switch ($ext) {
            '.html' { $ctype='text/html' }
            '.htm' { $ctype='text/html' }
            '.css' { $ctype='text/css' }
            '.js' { $ctype='application/javascript' }
            '.png' { $ctype='image/png' }
            '.jpg' { $ctype='image/jpeg' }
            '.jpeg' { $ctype='image/jpeg' }
            '.gif' { $ctype='image/gif' }
            '.svg' { $ctype='image/svg+xml' }
            '.ico' { $ctype='image/x-icon' }
            default { $ctype='application/octet-stream' }
        }
        $response.ContentType = $ctype
        $bytes = [System.IO.File]::ReadAllBytes($localPath)
        $response.ContentLength64 = $bytes.Length
        $response.OutputStream.Write($bytes, 0, $bytes.Length)
        $response.OutputStream.Close()
        $response.Close()
    } catch [System.Exception] {
        Write-Host "Server error: $_"
    }
}
