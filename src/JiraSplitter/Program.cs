using System.Runtime.CompilerServices;
using System.Text;
using System.Xml.Linq;

namespace JiraSplitter
{
    internal class Program
    {
        static void Main(string[] args)
        {
            var file = @"Nucleus-JIRA.xml";
            var output = @"C:\Repos\github\ExampleDocs\JIRA\Nucleus Demo Modules";

            var xml = XDocument.Load(file);
            var converter = new ReverseMarkdown.Converter();

            if (!Directory.Exists(output))
            {
                Directory.CreateDirectory(output);
            }

            var items = xml.Element("rss").Element("channel").Elements("item");

            foreach (var item in items)
            {
                var title = (string)item.Element("title");
                var link = (string)item.Element("link");
                var project = (string)item.Element("project");
                var projectKey = (string)item.Element("project").Attribute("key");
                var key = (string)item.Element("key");
                var summary = (string)item.Element("summary");

                var type = (string)item.Element("type");
                var priority = (string)item.Element("priority");
                var status = (string)item.Element("status");
                var resolution = (string)item.Element("resolution");
                var assignee = (string)item.Element("assignee");
                var reporter = (string)item.Element("reporter");

                var html = (string)item.Element("description");
                var markdown = converter.Convert(html);

                var comments = string.Join(Environment.NewLine, item.Element("comments")?.Elements("comment")?.Select(x => $" - {x.Attribute("created")}: {converter.Convert((string)x)}")?? Enumerable.Empty<string>());

                var result = @$"# {title}

## Summary

{key} [{summary}]({link}) is related to {project}

- Type: {type}
- Priority: {priority}
- Status: {status}
- Resolution: {resolution}
- Assignee: {assignee}
- Reporter: {reporter}

## Description

{markdown}

## Comments

{comments}

";
                var clientTitle = new[] { '\\', '/', '&', ':', '\r', '\n', '\"', '\'' }.Aggregate(new StringBuilder(title), (sb, i) => sb.Replace(i, '-')).ToString();

                var fileName = Path.Combine(output, $"{clientTitle}.md");
                Console.WriteLine(title);
                File.WriteAllText(fileName, result);
            }

            Console.WriteLine("fin!");
        }
    }
}
