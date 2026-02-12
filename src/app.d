import std.stdio;
import std.file;
import std.path;
import std.format;
import std.getopt;
import core.stdc.stdlib : exit;
import frontend.lexer.lexer;
import frontend.lexer.tokens;
import common.reporter;

pragma(inline, true)
void showHelp()
{
	writeln("Usage: zinc [options] <file.zc>\n");
	writeln("Options:");
	writeln("    -h, --help     Show this help message");
	writeln("    -v, --version  Show compiler version");
	writeln();
	writeln("Examples:");
	writeln("    zinc -v");
	exit(0);
}

pragma(inline, true)
void showVersion()
{
	writeln("Zinc - v0.1.0");
	exit(0);
}

pragma(inline, true)
void error(string msg)
{
	writefln("Zinc error: %s", msg);
	exit(0);
}

pragma(inline, true)
string extractDir(string path)
{
	string dir = dirName(path);
	return dir == "." || dir == "" ? "." : dir;
}

void main(string[] args)
{
	if (args.length < 2)
		error("A '.zc' file is expected as an argument.");

	bool shVersion, shHelp;
	getopt(args, "h|help", &shHelp, "v|version", &shVersion);

	if (shVersion)
		showVersion();
	if (shHelp)
		showHelp();

	string filename = args[1];
	if (!exists(filename))
		error(format("File not found '%s'.", filename));

	// a.zc = 4 (min)
	if (filename.length < 4)
		error(format("Invalid file '%s'.", filename));

	if (extension(filename) != ".zc")
		error(format("File with invalid extension '%s'.", filename));

	string src = readText(filename);
	string dir = extractDir(src);

	ReporterError error = new ReporterError();
	try
	{
		Lexer l = new Lexer(src, filename, dir, error);
		Token[] tokens = l.tokenize();
		writeln(tokens);
		error.check();
	}
	catch (Exception e)
	{
		writeln(e);
	}
}
