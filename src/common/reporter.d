module common.reporter;

import frontend.lexer.tokens;
import std.format;
import std.stdio;
import std.file;
import std.array : split, replicate;
import core.stdc.stdlib : exit;

enum ReporterLevel : ubyte
{
    Warning,
    Error,
}

struct ZincError
{
    ReporterLevel level;
    string message;
    Position pos;
}

class ReporterError
{
private:
    ZincError[] errors;
    ZincError[] warnings;
    string[][string] cache; // lines[file]

    void show(ZincError zinc)
    {
        writefln("%s: %s", zinc.level == ReporterLevel.Error ? "error" : "warning", zinc.message);

        string fl = zinc.pos.filename;
        string[] content;

        if (fl in cache)
            content = cache[fl];
        else
        {
            content = readText(fl).split("\n");
            cache[fl] = content;
        }

        uint lstart = zinc.pos.start.line;
        uint lend   = zinc.pos.end.line;

        if (lstart > 1)
            writefln("%d   | %s", lstart - 1, content[lstart - 2]);

        for (uint i = lstart; i <= lend; i++)
        {
            string line = content[i - 1];
            writefln("%d   | %s", i, line);

            uint colStart = (i == lstart) ? zinc.pos.start.col : 0;
            uint colEnd   = (i == lend)   ? zinc.pos.end.col   : cast(uint) line.length;
            uint spanLen  = (colEnd > colStart) ? colEnd - colStart : 1;

            string linePrefix = replicate(" ", digits(i) + 4);
            writefln("%s%s%s^", linePrefix, replicate(" ", colStart), replicate("~", spanLen - 1));
        }

        if (lend < content.length)
            writefln("%d   | %s", lend + 1, content[lend]);

        writeln();
    }

    pragma(inline, true)
    uint digits(uint n)
    {
        if (n == 0) return 1;
        uint d = 0;
        while (n > 0) { n /= 10; d++; }
        return d;
    }

public:
    void makeError(string message, Position pos)
    {
        errors ~= ZincError(ReporterLevel.Error, message, pos);
    }

    void makeWarning(string message, Position pos)
    {
        warnings ~= ZincError(ReporterLevel.Error, message, pos);
    }

    void check(bool ext = false)
    {
        if (warnings.length > 0 || errors.length > 0)
        {
            foreach (ref ZincError err; errors)
                show(err);
            foreach (ref ZincError warn; warnings)
                show(warn);
            if (errors.length > 0 && ext)
                exit(1);
        }
    }
}

/*

error: MESSAGE
line-1
line       line_content
           ^~~~~~~~~~~~
line+1

*/
