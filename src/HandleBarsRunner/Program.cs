using HandlebarsDotNet;
using HandlebarsDotNet.Extension.Json;
using Microsoft.Data.SqlClient;
using System.Text;
using System.Text.Json;

namespace HandleBarsRunner
{
    internal class Program
    {
        static async Task Main(string[] args)
        {
            var sqlResource = "HandleBarsRunner.EnumerateDatabase.sql";
            using var sqlScriptStream = typeof(Program).Assembly.GetManifestResourceStream(sqlResource);
            using var sqlScriptReader = new StreamReader(sqlScriptStream);
            var sqlScript = sqlScriptReader.ReadToEnd();

            var connectionString = "Server=127.0.0.1;Database=GreenOnionDb;User ID=sa;Password=Gr33n0n!on;TrustServerCertificate=True;";
            using var sqlConn = new SqlConnection(connectionString);
            await sqlConn.OpenAsync();
            using var sqlCmd = new SqlCommand(sqlScript, sqlConn);
            using var sqlreader = sqlCmd.ExecuteReader();

            var sqlJson = new StringBuilder();
            while (sqlreader.Read())
            {
                using var textReader = sqlreader.GetTextReader(0);
                
                var text = textReader.ReadToEnd();
                sqlJson.Append(text);
            }

            var json = sqlJson.ToString();

            //var fileName = "dbSchema.json";
            var templateFile = "dbSchema.jdl.hbs";
            var outFile = "dbSchema.jdl";

            //using var jsonFile = File.OpenRead(fileName);
            var data = JsonDocument.Parse(json);

            // https://github.com/Handlebars-Net/Handlebars.Net

            var config = new HandlebarsConfiguration()
            {
                NoEscape = true,
            };
            var handlebar = Handlebars.Create(config);
            handlebar.Configuration.UseJson();

            var reader = new StreamReader(templateFile);
            var compiled = handlebar.Compile(reader);

            using var writer = File.CreateText(outFile);
            compiled(writer, context: data);
            await writer.FlushAsync();


        }
    }
}
