module src.frontend.lexer.tokens;

enum TokenKind : ubyte
{
    Identifier,
    
    // keyword
    Let,
    Const,
    Fn,
    Defer,
    Import,

    // literal
    Number, // 0..9
    Float, // 0.0F
    Double, // 0.0
    Bool, // true | false
    Null, // null | NULL

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

    Equals, // =
    EEquals, // ==

    LParen, // (
    RParen, // )
    LBRace, // {
    RBrace, // }
    LBRacket, // [
    RBRacket, // ]

    Eof,
}
