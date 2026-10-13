# =====================================================================
#  Contrôleur de domaine AD-LOTIE (Windows Server 2019 Core, 192.168.10.40)
#  À exécuter dans PowerShell, en administrateur.
#  Les mots de passe sont demandés à l'exécution : rien n'est écrit en clair.
# =====================================================================

# --- 1. Promotion en contrôleur de domaine (une seule fois, redémarre la machine) ---
# Install-WindowsFeature AD-Domain-Services -IncludeManagementTools
# Install-ADDSForest -DomainName "lotietelecom.local" -InstallDns

# --- 2. Vérifications après redémarrage ---
Get-Service NTDS, DNS, Netlogon      # les trois doivent être "Running"
dcdiag /test:dns                     # résolution DNS du domaine

# --- 3. Comptes de test ---
New-ADUser -Name "employe1" -SamAccountName "employe1" `
  -UserPrincipalName "employe1@lotietelecom.local" `
  -AccountPassword (Read-Host -AsSecureString "Mot de passe employe1") -Enabled $true
New-ADUser -Name "it1" -SamAccountName "it1" `
  -UserPrincipalName "it1@lotietelecom.local" `
  -AccountPassword (Read-Host -AsSecureString "Mot de passe it1") -Enabled $true

# --- 4. Groupes utilisés par les règles d'autorisation d'ISE ---
New-ADGroup -Name "Collaborateurs" -GroupScope Global -GroupCategory Security
New-ADGroup -Name "IT" -GroupScope Global -GroupCategory Security
Add-ADGroupMember -Identity "Collaborateurs" -Members "employe1"
Add-ADGroupMember -Identity "IT" -Members "it1"

# --- 5. Heure : indispensable pour Kerberos (écart max 5 min avec ISE) ---
Set-TimeZone -Id "Greenwich Standard Time"     # UTC+0, fuseau de Lomé
# Recaler l'heure sur celle d'ISE (relevée avec "show clock" sur ISE) :
# Set-Date -Date "JJ/MM/AAAA HH:MM:SS"
