<h1 align="center">
  <br>
  SQLdictionary
  <br>
</h1>
<h4 align="center">📕 A SQL data dictionary implemented in <a href="https://github.com/PowerShell/PowerShell" target="_blank">Powershell Core</a> with <a href="https://github.com/Stephanevg/PSHTML" target="_blank">PSHTML</a> module.</h4>

<p align="center">
  <a href="#how-to-use">How to use</a> •
  <a href="#tested-with">Tested with</a> •
  <a href="#credits">Credits</a> •
  <a href="#contributing">Contributing</a> •
  <a href="#license">License</a>
</p>

![screenshot](https://raw.githubusercontent.com/AkioCode/SQLdictionary/master/app/img/demo.gif)

## How to use

To clone and run this application, you'll need [Git](https://git-scm.com), [Powershell Core](https://github.com/PowerShell/PowerShell/releases) installed on your computer. From your powershell command line:

```powershell
# Upgrade to Powershell's latest stable version 
$ iex "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI"

# Or upgrade to Powershell's preview version
$ iex "& { $(irm https://aka.ms/install-powershell.ps1) } -UseMSI -Preview"

# Clone this repository
$ git clone https://github.com/AkioCode/SQLdictionary.git

# Go into the program's folder
$ cd .\SQLdictionary\app\scripts

# Run the app
$ .\Export-Dictionary.ps1 -OutFile "~\path\to\output"
```

Note: If you're using PostgreSQL, you'll need to install [PostgreSQL ODBC Driver](https://odbc.postgresql.org).

## Tested with
  - 🐘 PostgreSQL 12 and above;
  - 🧬 SQL Server 2017.

## Credits

This software uses the following open source packages:

- 💪 [Powershell Core](https://github.com/PowerShell/PowerShell)
- 📦 [PSHTML](https://github.com/Stephanevg/PSHTML)
- 📦 [SqlServer (PS Module)](https://docs.microsoft.com/pt-br/sql/powershell/download-sql-server-ps-module?view=sql-server-ver15)
- 💅 HTML layout and style were taken from [here](https://pgmodeler.io)
- 🔰 Logo was taken from [here](https://www.flaticon.com/br/)

## Contributing

📥 Pull requests and 🌟 Stars are always welcome !

## License

🏛 MIT

---
