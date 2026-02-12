module frontend.lexer.tokens;

enum TokenKind : ubyte
{
    Identifier,
    
    // keyword
    Let,
    Const,
    Fn,
    Defer,
    Import,
    If,
    Else,
    Return,
    Def,

    // literal
    Number, // 0..9
    Float, // 0.0F
    Double, // 0.0
    Bool, // true | false
    Null, // null | NULL
    String, // "fernando"
    False,
    True,

    // symbols
    Plus, // +
    PPlus, // ++
    Minus, // -
    MMinus, // --
    Star, // *
    Slash, // /
    Modulo, // %
    Pipe, // |
    Tilde, // ~
    Ampersand, // &
    Lt, // <
    Gt, // >

    Equals, // =
    EEquals, // ==

    LParen, // (
    RParen, // )
    LBRace, // {
    RBrace, // }
    LBRacket, // [
    RBRacket, // ]

    Colon, // :
    SemiColon, // ;
    Comma, // ,
    
    Arrow, // ->

    Eof,
}

struct LinePos {
    uint col;
    uint line;
}

struct Position {
    string filename;
    string dir;
    LinePos start, end;
}

union TokenValue {
    string str;
    char ch;
    long number;
    float f32;
    double f64;
}

struct Token {
    TokenKind kind;
    TokenValue value;
    Position pos;
}
