Write-Host "Launching Microsoft Edge in headless mode..."
$edgeProcess = Start-Process "msedge.exe" -ArgumentList "--headless", "--disable-gpu", "http://localhost:8084/" -PassThru

$timeout = 30
$elapsed = 0
$completed = $false

while ($elapsed -lt $timeout) {
    Start-Sleep -Seconds 1
    $elapsed++
    
    if (Test-Path "debug.log") {
        $content = Get-Content "debug.log" -ErrorAction SilentlyContinue
        if ($content -match "TEST_COMPLETED") {
            Write-Host "Test completed successfully!"
            $completed = $true
            break
        }
        if ($content -match "TEST_FAILED") {
            Write-Host "Test encountered a failure!"
            $completed = $true
            break
        }
    }
}

if (-not $completed) {
    Write-Host "Test timed out!"
}

Write-Host "Stopping Edge process..."
Stop-Process -Id $edgeProcess.Id -Force
