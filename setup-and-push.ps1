$ErrorActionPreference = "Stop"
Set-Location "D:\1A\zhixia\qinglingwallet"
$env:HTTPS_PROXY = "http://127.0.0.1:7890"
$env:HTTP_PROXY  = "http://127.0.0.1:7890"
git branch -M main
Write-Host "正在创建 GitHub 私有仓库并推送..."
gh repo create qinglingwallet --private --description "清零记账 - 简洁易用、高度个人化的记账App" --source . --remote origin --push
if ($LASTEXITCODE -eq 0) { Write-Host "OK！云端构建已触发。" } else { Write-Host "失败，请看上面的报错。" }
