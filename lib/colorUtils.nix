# Framework for working with colors in different formats
{ pkgs, ... }:

let
  inherit (pkgs.lib.strings) fixedWidthString stringToCharacters removePrefix toUpper;
  inherit (pkgs.lib.trivial) toHexString;
  inherit (pkgs.lib.lists) imap0 foldr reverseList;
  inherit (builtins) substring stringLength elem elemAt;
in
rec {
  # Convert 0-255 color part representation to 00-FF
  toHex = color:
    fixedWidthString 2 "0" (toHexString color);

  # Convert 00-FF color part representation to 0-255
  fromHex = string:
    let
      fromHexDigit = d:
        {
          "0" = 0;
          "1" = 1;
          "2" = 2;
          "3" = 3;
          "4" = 4;
          "5" = 5;
          "6" = 6;
          "7" = 7;
          "8" = 8;
          "9" = 9;
          "A" = 10;
          "B" = 11;
          "C" = 12;
          "D" = 13;
          "E" = 14;
          "F" = 15;
        }."${toUpper d}";

      pow = a: n:
        if n == 0 then 1
        else if n == 1 then a
        else (pow a (n - 1)) * a;
      # else foldr(v : sum: v * a + sum) 0 (genList (i: n) (n - 1));

      chars = stringToCharacters string;
      numeric = imap0 (i: v: (pow 16 i) * (fromHexDigit v)) (reverseList chars);
    in
    foldr (v: sum: sum + v) 0 numeric;

  # Makes a comprehensive color structure with different formats.
  # Color inputs should be a 0-255 int number.
  #
  # It is possible to modify any color to create a new color with
  # color.modify or color.modifyHex functions.
  # The regular modify accepts an attrset with optional a, r, g, b values (any or none),
  # while the hex version accepts hexA, hexR, hexG, hexB.
  mkColor = r: g: b: a:
    rec {
      inherit r g b a;
      hexR = "${toHex r}";
      hexG = "${toHex g}";
      hexB = "${toHex b}";
      hexA = "${toHex a}";
      hexRGBbase = "${hexR}${hexG}${hexB}";
      hexRGB = "#${hexRGBbase}";
      hexRGBAbase = "${hexR}${hexG}${hexB}${hexA}";
      hexRGBA = "#${hexRGBAbase}";
      hexARGBbase = "${hexA}${hexR}${hexG}${hexB}";
      hexARGB = "#${hexARGBbase}";

      modify = modifiers:
        mkColor
          (modifiers.r or r)
          (modifiers.g or g)
          (modifiers.b or b)
          (modifiers.a or a);

      modifyHex = hexModifiers:
        mkColorHex "#${hexModifiers.r or hexR} ${hexModifiers.g or hexG} ${hexModifiers.b or hexB} ${hexModifiers.a or hexA}";
    };

  # Makes a color structure, but from the string. See mkColor for more info.
  # Format: #RRGGBBAA or #RRGGBB
  mkColorHex = string:
    let
      partialParse = string:
        let l = stringLength string; in
        assert l >= 2;
        if l == 2 then [ (fromHex string) ]
        else (partialParse (substring 0 2 string)) ++ (partialParse (substring 2 (l - 2) string));

      hex = removePrefix "#" string;
      colors = partialParse hex;
      color = mkColor
        (elemAt colors 0)
        (elemAt colors 1)
        (elemAt colors 2)
        (if (elem 3 colors) then (elemAt colors 3) else 255);
    in
    # pkgs.lib.debug.traceValFn (c: "${c.hexRGB} = { r: ${toString c.r}, g: ${toString c.g}, b: ${toString c.b}, a: ${toString c.a} }") 
    color;
}
