Vector{UInt8}(
"POST http://something.com/path HTTP/1.1\r\n" *
"Host: www.somewhere.com\r\n" *
"Transfer-Encoding: chunked\r\n" *
"\r\n" *
"24\r\n" *
"'Twas brillig, and the slithy toves\n" *
"27\r\n" *
"      Did gyre and gimble in the wabe:\n" *
"1E\r\n" *
"All mimsy were the borogoves,\n" *
"22\r\n" *
"      And the mome raths outgrabe." *
"0\r\n" *
"Happiness: 100\r\n" *
"Author: Lewis Carroll\r\n" *
"\r\n"
)
