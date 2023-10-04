# Enable TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Define your Nextcloud address
$NextcloudUrl = "https://nc.sazam.co.uk"

# Define the shared token got from the shared link
$sharetoken = "Xj5FQrH3Hj69GJ8"

# Define folder path where are the files you would like to upload. It can upload only files not folders.
# It doens't know about override, will create a duplicate in case you run it twice and the same file name is there.
$filepath = "C:\Users\drew\Desktop\sc-100"

# Getting all the files in the specified folder
$Item = Get-ChildItem -Recurse $filepath | Sort-Object fullname | Select FullName

# Will process each file individually and upload them to the cloud.
$Item | ForEach-Object {

    $file = $_.FullName

$Item = Get-Item $file

$Headers = @{
    "Authorization"=$("Basic $([System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($("$($sharetoken):"))))");
    "X-Requested-With"="XMLHttpRequest";
}
$webdav = "$($NextcloudUrl)/public.php/webdav/$($Item.Name)"
Invoke-RestMethod -Uri $webdav -InFile $Item.Fullname -Headers $Headers -Method Put
}