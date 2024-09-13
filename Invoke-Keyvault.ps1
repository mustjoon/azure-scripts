function Login {
    param (
        [string]$email,
        [string]$password
    )

    $pass = ConvertTo-SecureString "$password" -AsPlainText -Force;
    $cred = New-Object System.Management.Automation.PSCredential("$email", $pass);
    Connect-AzAccount  -Credential $cred
}

function GetVaults() {
    Write-Host "Getting vaults"
    $vaults = Get-AzKeyVault
    Write-Host("Got "+$vaults.Count + " vault(s)")
    return $vaults 
}

function GetRemovedVaults() {
    Write-Host "Getting removed vaults"
    $removedVaults = Get-AzKeyVault -InRemovedState
    Write-Host("Got "+$removedVaults.Count + " removed vault(s)")
    return $vaults
}

function GetSecrets() {
     param (
        [Object]$vault
    )
    $secrets = Get-AzKeyVaultSecret -VaultName $vault.VaultName
    return $secrets
}

function GetKeys() {
     param (
        [Object]$vault
    )
    $secrets = Get-AzKeyVaultKey -VaultName $vault.VaultName
    return $secrets
}
function GetRemovedKeys() {
     param (
        [Object]$vault
    )
    $secrets = Get-AzKeyVaultKey -VaultName $vault.VaultName -InRemovedState 
    return $secrets
}

function GetRemovedSecrets() {
     param (
        [Object]$vault
    )
    $secrets = Get-AzKeyVaultSecret -VaultName $vault.VaultName -InRemovedState
    return $secrets
}

function Enumerate() {
    $vaults = GetVaults;
    $vaults | ForEach-Object -Process {
        $vault = $_
        $secrets = GetSecrets -vault $vault
        $removedSecrets = GetRemovedSecrets -vault $vault

        Write-Host("------------------------------------")
        Write-Host "Secrets:"
        $secrets | ForEach-Object -Process {
            $secret = $_;
            Write-Host "Secret" $secret.Name
            if($secret.Tags -ne $null -and $secret.Tags.Count -gt 0) {
                foreach ($tag in $secret.tags.Keys) {
                    $tagName = $tag
                    $tagValue = $secret.Tags[$tag]
                    Write-Output "Tag Name: $tagName, Tag Value: $tagValue"
                }
            }
           
            $command = "Get-AzKeyVaultSecret -VaultName "+$vault.VaultName+" -Name "+$secret.Name+" -AsPlainText"
            Write-Host $command;
            $versions = Get-AzKeyVaultSecret -Vaultname $vault.VaultName -Name $secret.Name -IncludeVersions;

            if($versions.Count -gt 1) {
                $command = "Get-AzKeyVaultSecret -VaultName "+$vault.VaultName+" -Name "+$secret.Name+ " -IncludeVersions"
                Write-host "Secret has other versions, run command : $command";
                
            }
        }

        $removedSecrets | ForEach-Object -Process {
            $secret = $_;
            Write-Host "Found removed secret" $secret.Name ", run command below to try to recover it:"
            Write-host "Undo-AzKeyVaultSecretRemoval -VaultName" $vault.VaultName "-Name" $secret.Name
            
        }
        Write-Host("------------------------------------")
        Write-Host("KEYS")
        Write-Host("------------------------------------")
        $keys = GetKeys -vault $vault

        $keys  | ForEach-Object -Process {
            $key = $_
            Write-Host "Key:" $key.Name;
            if($key.Tags -ne $null -and $key.Tags.Count -gt 0) {
                foreach ($tag in $secret.tags.Keys) {
                    $tagName = $tag
                    $tagValue = $key.Tags[$tag]
                    Write-Output "Tag Name: $tagName, Tag Value: $tagValue"
                }
            }
            $InfoCommand = "Get-AzKeyVaultKey -VaultName "+$vault.VaultName+" -Name "+$key.Name
            Write-Host $InfoCommand;

            $versions = Get-AzKeyVaultKey -Vaultname $vault.VaultName -Name $key.Name -IncludeVersions;

            if($versions.Count -gt 1) {
                $command = "Get-AzKeyVaultKey -VaultName "+$vault.VaultName+" -Name "+$key.Name+ " -IncludeVersions"
                Write-host "Key has other versions, run command : $command";
               
                #Write-Host "Get-AzKeyVaultSecret -VaultName" $vault.VaultName "-Name" $secret.Name "-IncludeVersions"
            }
        }
        $deletedKeys = GetRemovedKeys -vault $vault;
        $deletedKeys | ForEach-Object -Process {
            $key = $_;
            Write-Host "Found removed key" $key.Name ", run command below to try to recover it:"
            Write-host "Undo-AzKeyVaultKeyRemoval -VaultName" $vault.VaultName "-Name" $key.Name
            $InfoCommand = "Get-AzKeyVaultKey -VaultName "+$vault.VaultName+" -Name "+$key.Name
           
            Write-Host $InfoCommand
        }
        Write-Host("------------------------------------")
    }
    $removedVaults = GetRemovedVaults
   
    $removedVaults | ForEach-Object -Process {
        Write-Host $_.Name
    }
    Write-Host $removedVaults;
}


Enumerate
