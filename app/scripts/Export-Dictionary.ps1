[CmdletBinding()]
param (
    [Parameter()]
    [string]
    $OutFile
)

# This is for default input values
function Set-DefaultValue {
    param (
        [Parameter(Mandatory=$True)][string]$Prompt
        ,[Parameter(Mandatory=$True)][string]$default
        ,[bool]$securityString=$False
    )
    if ($securityString) {
        $Output = Read-Host $Prompt -MaskInput
    }
    else{
        $Output = Read-Host $Prompt
    }

    if ([string]::IsNullOrWhiteSpace($Output)) {
        return $default
    }
    return $Output
}

# This is for mandatory inputs
function Get-NonNullString{
    Param(
        [string]$Prompt=(throw "You must provide text as a prompt")
        ,[Parameter(Mandatory=$false)][System.Collections.ArrayList]$Check
        )
    $Out = Read-Host $Prompt
    if($Check.Count -gt 0){
        While($Out -inotin $Check){
            write-host "`nYou must enter a valid response!`n" -ForegroundColor Red
            $Out = Read-Host $prompt
        }
    }
    While([string]::IsNullOrWhiteSpace($Out)){
        write-host "`nYou must enter a response!`n" -ForegroundColor Red   
        $Out = Read-Host $Prompt
    }
    return $Out
}

# This is for PostgreSQL queries
function Get-ODBCData{  
    param(
          [string]$query,                   # Query to retrieve data
          [string]$dbServer = "localhost",  # DB Server (either IP or hostname)
          [string]$dbPort = "5432",         # DB Server's port
          [string]$dbName   = "postgres",   # Name of the database
          [string]$dbUser   = "postgres",   # User we'll use to connect to the database/server
          [string]$dbPass   = "postgres"    # Password for the $dbUser
         )

    $conn = New-Object System.Data.Odbc.OdbcConnection
    $conn.ConnectionString = "Driver={PostgreSQL Unicode(x64)};Server=$dbServer;Port=$dbPort;Database=$dbName;Uid=$dbUser;Pwd=$dbPass;"
    try {
        $conn.Open()
        $cmd = New-object System.Data.Odbc.OdbcCommand($query,$conn)
    }
    catch {
        Write-Host "`n[❌] Connection failed with $dbName ! Please verify data connection and try again.`n" -ForegroundColor Red -
        return
    }
    Write-Verbose "`n[✔] Connection succeded with $dbName !`n"
    Write-Verbose "`n[🖇] Connection data:`n    - Server: $dbServer`n    - Database: $dbName`n    - User: $dbUser`n"
    $ds = New-Object system.Data.DataSet
    (New-Object system.Data.odbc.odbcDataAdapter($cmd)).fill($ds) | out-null
    Write-Verbose "`n[✔] Query succeded !`n"
    $conn.close()
    $ds.Tables[0]
}

# This is for SQLServer queries
function Get-SSData {
    param(
          [string]$query,                           # Query to retrieve data
          [string]$dbServer = "DESKTOP-123ABC\SQL", # DB Server (either IP or hostname)
          [string]$dbPort = "1433",                 # DB Server's port
          [string]$dbName   = "master",             # Name of the database
          [string]$dbUser   = "sa",                 # User we'll use to connect to the database/server
          [string]$dbPass   = "sa"                  # Password for the $dbUser
         )
    Invoke-Sqlcmd -Query $query -ServerInstance $dbServer -Database $dbName -Username $dbUser -Password $dbPass
}

# This makes an enumerated list of the databases from a PostgreSQL cluster
function Select-PGDatabase {
    param (
        [hashtable]$conn
    )
    [System.Collections.ArrayList]$dbs = @()
    [hashtable]$hashDBs = @{}
    $sqlDBs = Get-Content -Path .\PG\SELECT_DATABASES.sql | Out-String
    $dbs = Get-ODBCData -query $sqlDBs -dbServer $conn["host"] -dbPort $conn["port"] -dbUser $conn["user"] -dbPass $conn["pwd"]

    Write-Host "Choose a database below:"
    for ($i = 0; $i -lt $dbs.Count; $i++) {
        $hashDBs[$i] = $dbs[$i].Item(0)
        Write-Host "`t($i) - $($dbs[$i].Item(0))" -ForegroundColor Yellow
    }
    [int]$number = Read-Host -Prompt "Number"
    return $hashDBs[$number]
}

# This makes an enumerated list of the databases from a SqlServer cluster
function Select-SSDatabase {
    param (
        [hashtable]$conn
    )
    [hashtable]$hashDBs = @{}
    $sqlDBs = Get-Content -Path ".\SS\SELECT_DATABASES.sql" | Out-String
    $dbs = Get-SSData -query $sqlDBs -dbServer $conn["host"] -dbUser $conn["user"] -dbPass $conn["pwd"]
    Write-Host "Choose a database below:"
    for ($i = 0; $i -lt $dbs.Count; $i++) {
        $hashDBs[$i] = $dbs[$i].Item(0)
        Write-Host "`t($i) - $($dbs[$i].Item(0))" -ForegroundColor Yellow
    }
    [int]$number = Read-Host -Prompt "Number"
    return $hashDBs[$number]
}

# This is to get connection data to PostgreSQL
function Connect-Postgres {
    [hashtable]$hash = @{}
    $hash["host"] = Set-DefaultValue -Prompt "Type the host's IP (localhost)" -default "localhost"
    $hash["port"] = Set-DefaultValue -Prompt "Type the port (5432)" -default "5432"
    $hash["user"] = Set-DefaultValue -Prompt "Type the database user (postgres)" -default "postgres"
    $hash["pwd"]  = Set-DefaultValue -Prompt "Type the database user password (********)" -default "postgres" -securityString $True
    return $hash
}

# This is to get connection data to SQLServer (Maybe can it be just one function for ?).
function Connect-SqlServer {
    [hashtable]$hash = @{}
    $hash["host"] = Get-NonNullString -Prompt "Type the server instance"
    $hash["port"] = Set-DefaultValue -Prompt "Type the port (1433)" -default "1433"
    $hash["user"] = Set-DefaultValue -Prompt "Type the database user (sa)" -default "sa"
    $hash["pwd"]  = Set-DefaultValue -Prompt "Type the database user password (***********)" -default "mssqlserver" -securityString $True    
    return $hash
}

# This is... Well... this makes the whole thing
function Main {
    <#
    .SYNOPSIS
    
    Generates a html data dictionary from a target database.
    
    .DESCRIPTION
    
    Generates a html data dictionary from a target database.
    The program asks for the user the dbms of the database.
    The program waits for user inputs the correspoding data 
    of the connection string to the target database.
    
    .PARAMETER Verbose
    Enable prints during the script's execution-time.
    
    .INPUTS
    
    None. You cannot pipe objects to Add-Extension.
    
    .OUTPUTS
    
    Returns a html data dictionary from a target database.
    
    .EXAMPLE
    
    PS> Main
    
    .EXAMPLE
    
    PS> Main -Verbose
    
    .LINK
    
    http://www.fabrikam.com/extension.html
    
    .LINK
    
    Set-Item
    #>
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$false)][string]$path
    )
    # Constants and variables section of the Main function
    $cssFile = Get-Content -Path "Dictionary-Style.css"
    [hashtable]$connHash
    [string]$dbname
    [string]$dbms = Get-NonNullString -Prompt "Choose one of the database target's DBMS below `n`    - Sql Server (SS)`n    - PostgreSQL (PG)`nType the content between parenthesis" -Check @("PG","SS")
    [string]$appName = Read-Host -Prompt "Type the application name (optional)"
    [System.Collections.ArrayList]$consList = @()
    [System.Collections.ArrayList]$colsList = @()

    # Installing modules section
    If($null -eq (Get-InstalledModule | Where-Object {$_.Name -ieq "pshtml"})){ 
        Write-Host '[📦] Installing module PSHTML ...'
        Install-Module -Name PSHTML -Confirm -Force -AllowClobber
    }
    If($null -eq (Get-InstalledModule | Where-Object {$_.Name -ieq "sqlserver"})){ 
        Write-Host '[📦] Installing module SQLSERVER ...'
        Install-Module -Name sqlserver -Confirm -Force -AllowClobber
    }

    <#  Water division section 
        aka DBMS segregation section  #>
    switch ($dbms) {
        "pg" {
            Write-Verbose "[🐘] PostgreSQL was choosed !"
            $constraintSql = Get-Content -Path ".\PG\SELECT_CONSTRAINTS.sql" | Out-String
            $columnsSql = Get-Content -Path ".\PG\SELECT_COLUMNS.sql" | Out-String
            $connHash = Connect-Postgres
            $dbname = Select-PGDatabase -conn $connHash
            Write-Verbose "[⏳] Trying connection to $dbname !"
            $consList = Get-ODBCData -query $constraintSql -dbServer $connHash["host"] -dbPort $connHash["port"] -dbName $dbname -dbUser $connHash["user"] -dbPass $connHash["pwd"]
            Write-Verbose "[⏳] Trying connection to $dbname !"
            $colsList = Get-ODBCData -query $columnsSql -dbServer $connHash["host"] -dbPort $connHash["port"] -dbName $dbname -dbUser $connHash["user"] -dbPass $connHash["pwd"]
        }
        "ss" {
            Write-Verbose "[🧬] Sql Server was choosed !"
            $constraintSql = Get-Content -Path ".\SS\SELECT_CONSTRAINTS.sql" | Out-String
            $columnsSql = Get-Content -Path ".\SS\SELECT_COLUMNS.sql" | Out-String
            $connHash = Connect-SqlServer
            $dbname = Select-SSDatabase -conn $connHash
            Write-Verbose "[⏳] Trying connection to $dbname !"
            $consList = Get-SSData -Query $constraintSql -dbServer $connHash["host"] -dbName $dbname -dbUser $connHash["user"] -dbPass $connHash["pwd"]
            Write-Verbose "[⏳] Trying connection to $dbname !"
            $colsList = Get-SSData -Query $columnsSql -dbServer $connHash["host"] -dbName $dbname -dbUser $connHash["user"] -dbPass $connHash["pwd"]
        } 
    }
    [string]$dictNameNoEscaped
    if ([string]::IsNullOrEmpty($appName)) {
        $dictNameNoEscaped += $dbname.ToUpper() 
    }
    else{
        $dictNameNoEscaped += $appName.ToUpper()
    }

    Write-Verbose "[⏳] Formatting extracted data"

    #   Data formating variables
    $tables = $colsList | Group-Object -Property SCHEMA, TABLE | 
    Select-Object -Property @{Expression={$_.Name.Replace(', ','.')};Name='name'}, @{Expression={$_.Group};Name='column'}
    Write-Verbose "[✔] Data formatting succeded"
    
    <#  This is where the fun starts...
        Whatever, its the HTML layout generation section  #>   
    $Html = html {
        head {
            meta -charset 'utf-8' 
            Title "SQLdictionary - $dictNameNoEscaped"
            style -Content $cssFile -Type 'text/css'
            Link -href "../img/favicon.png" -rel "icon" -type "img/png" -Attributes @{sizes="512x512"}
        }
        Body{
            H2 'Index'
            ul -Id 'index' {
                li {
                    strong -Content "Database: $($dbname.ToUpper())"
                }
                if (![string]::IsNullOrEmpty($appName)) {
                    li {
                        strong -Content "Application: $($appName.toUpper())"
                    }
                }
                br
                li {
                    strong -Content 'Tables:'
                    Write-Verbose "[⏳] Constructing index"
                    foreach ($table in $tables) {
                        $fullTableName = $table.name
                        ul {
                            li -Content {
                                a -Content $fullTableName -href "#$fullTableName"
                            }
                        }
                    }
                    Write-Verbose "[✔] Index done"
                }
            }
            $tableCounter = 0
            Write-Verbose "[⏳] Constructing tables"
            foreach ($table in $tables) {
                $fullTableName = $table.name
                $schemaName = $table.name.Split('.')[0]
                $tableName = $table.name.Split('.')[1]
                Write-Progress -Id 1 -Activity "[⏳] Current table: $fullTableName" -Status "($tableCounter/ $($tables.Count)) tables done" -PercentComplete ($tableCounter*100/$($tables.Count))
                PSHTML\Table -Id "$($table.name)" -Class "table" -Content {
                    Caption -Class "tab-name" -Content {
                        em -Content $schemaName
                        "."
                        strong -Content $tableName
                        span -Class "type-label" -Content "Table"
                    }
                    Thead -Content{
                        tr -Content { 
                            th "Name"
                            th "Type"
                            th "NN"
                            th "UQ"
                            th "PK"
                            th "FK"
                            th "CK"
                            th "DF"
                            th "Description"
                        }
                    }
                    Tbody -Content {
                        foreach ($column in $table.column) {
                            tr -Content {
                                td $column.NAME
                                td -Class "data-type"   -Content $column.TYPE
                                td -Class "bool-field"  -Content $column.NN
                                td -Class "bool-field"  -Content $column.UQ
                                td -Class "bool-field"  -Content $column.PK
                                td -Class "bool-field"  -Content $column.FK
                                td -Class "value"       -Content $column.CK
                                td -Class "value"       -Content $column.DF
                                td -Class "value"       -Content {
                                    em  -Content $column.COMMENT
                                } 
                            }
                        }
            
                        $constraints = $consList.Where({$_.TABLE -eq $tableName})   
                        
                        tr {
                            td -Class "nested-tab-parent" -Attributes @{colspan = 9}{
                                PSHTML\Table -Class "nested-tab" -Content {
                                    tr -Content {
                                        td -Class "title" -Attributes @{colspan = 7}{
                                            "Constraints"
                                        }
                                    } #$consFileHeader = "TABLE","COLUMN","NAME","TYPE","REFERENCES","ONUPDATE","ONDELETE","COMMENT"
                                    tr -Content {
                                        td -Class "title" "Name"
                                        td -Class "title" "Type"
                                        td -Class "title" "Column"
                                        td -Class "title" "References"
                                        td -Class "title" "ONUPD"
                                        td -Class "title" "ONDEL"
                                        td -Class "title" "Comment"
                                    }
                                    foreach ($constraint in $constraints) {
                                        tr -Content {
                                            td $constraint.NAME
                                            td -Class "value constr-type" $constraint.TYPE
                                            td $constraint.COLUMN
                                            if($constraint.REFERENCES -eq '➖'){
                                                td -Class "value" "➖"
                                            }
                                            else{
                                                td -Class "value" "$($constraint.REFERENCES)"
                                            }
                                            td -Class "value" $constraint.ONUPDATE
                                            td -Class "value" $constraint.ONDELETE
                                            td -Class "value" -Attributes @{colspan = 4}{
                                                em "$($constraint.COMMENT)"
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Div {
                        a -Class "nav-link" -href "#index"{
                            "Index"
                        }
                    }
                }
                $tableCounter++   
            }
            Write-Verbose "[✔] Tables done"
        }
        Footer {
            h4 -Content {
                '💖 Credits to '
                a -href 'https://pgmodeler.io' -Content{
                    'pgModeler'
                }
                ' for providing this awesome HTML layout.'
            }
        }
    }

    $dictNameNoEscaped += Get-Date -Format "_mmHHddMMyy"
    $dictNameNoEscaped += ".html"
    $dictName = [WildcardPattern]::Escape($dictNameNoEscaped)
    
    Write-Verbose "[⏳] Generating HTML data dictionary"
    $Html | Out-File -FilePath "$OutFile$dictName"
    Write-Verbose "[✔] HTML Data dictionary generating succeded"
}

#   This is the way ~ Mandalorian
Main -Verbose

#   "Money, que é good nóis não have."