module Test.Data.String.Utils
  ( testStringUtils )
where

import Control.Monad.Eff.Console (log)
import Data.Maybe                (Maybe (Just, Nothing))
import Data.String               as Data.String
import Data.String.Utils         ( NormalizationForm(NFC), charAt, codePointAt
                                 , codePointAt', endsWith, endsWith'
                                 , escapeRegex, filter, fromCharArray, includes
                                 , includes', length, lines, mapChars, normalize
                                 , normalize', repeat, replaceAll, startsWith
                                 , startsWith', stripChars, stripDiacritics
                                 , toCharArray, unsafeCodePointAt
                                 , unsafeCodePointAt', unsafeRepeat, words
                                 )
import Prelude
import Test.Input                ( NegativeInt(NegativeInt)
                                 , NewlineChar(NewlineChar)
                                 , NonNegativeInt(NonNegativeInt)
                                 , WhiteSpaceChar(WhiteSpaceChar)
                                 )
import Test.StrongCheck          (Result, SC, (===), assert, quickCheck)

testStringUtils :: SC () Unit
testStringUtils = do
  log "charAt"
  let
    charAtEmptyStringProp :: Int -> Result
    charAtEmptyStringProp n = charAt n "" === Nothing

  assert $ charAt 2 "ℙ∪𝕣ⅇႽ𝚌𝕣ⅈ𝚙†" === Just "𝕣"
  quickCheck charAtEmptyStringProp

  log "codePointAt"
  assert $ codePointAt  0 ""           === Nothing
  assert $ codePointAt  0 "a"          === Just 97
  assert $ codePointAt  1 "a"          === Nothing
  assert $ codePointAt  0 "ab"         === Just 97
  assert $ codePointAt  1 "ab"         === Just 98
  assert $ codePointAt  2 "ab"         === Nothing
  assert $ codePointAt  0 "∀"          === Just 8704
  assert $ codePointAt  1 "∀ε"         === Just 949
  assert $ codePointAt  0 "𝟘𝟙𝟚𝟛𝟜𝟝𝟞𝟟𝟠𝟡" === Just 120792
  assert $ codePointAt  1 "𝟘𝟙𝟚𝟛𝟜𝟝𝟞𝟟𝟠𝟡" === Just 120793
  assert $ codePointAt 19 "𝟘𝟙𝟚𝟛𝟜𝟝𝟞𝟟𝟠𝟡" === Nothing

  log "codePointAt'"
  assert $ codePointAt'  0 ""           === Nothing
  assert $ codePointAt'  0 "a"          === Just 97
  assert $ codePointAt'  1 "a"          === Nothing
  assert $ codePointAt'  0 "ab"         === Just 97
  assert $ codePointAt'  1 "ab"         === Just 98
  assert $ codePointAt'  2 "ab"         === Nothing
  assert $ codePointAt'  0 "∀"          === Just 8704
  assert $ codePointAt'  1 "∀ε"         === Just 949
  assert $ codePointAt'  0 "𝟘𝟙𝟚𝟛𝟜𝟝𝟞𝟟𝟠𝟡" === Just 120792
  assert $ codePointAt'  1 "𝟘𝟙𝟚𝟛𝟜𝟝𝟞𝟟𝟠𝟡" === Just 57304
  assert $ codePointAt' 19 "𝟘𝟙𝟚𝟛𝟜𝟝𝟞𝟟𝟠𝟡" === Just 57313

  log "endsWith"
  let
    endsWithSubsetProp :: String -> Result
    endsWithSubsetProp str = endsWith str str === true

    endsWithEmptyStringProp :: String -> Result
    endsWithEmptyStringProp str = endsWith "" str === true

  assert $ endsWith "Script" "PureScript" === true
  assert $ endsWith "happy ending" "火垂るの墓" === false
  quickCheck endsWithSubsetProp
  quickCheck endsWithEmptyStringProp

  log "endsWith'"
  let
    -- Note that the `position` argument is translated to
    -- `min(max(pos, 0), len)``
    -- Cf. http://www.ecma-international.org/ecma-262/6.0/#sec-string.prototype.endswith
    endsWith'EmptyStringProp :: String -> Int -> Result
    endsWith'EmptyStringProp str n = endsWith' "" n str === true

  assert $ endsWith' "Pure" 4 "PureScript" === true
  assert $ endsWith' "Script" 4 "PureScript" === false
  quickCheck endsWith'EmptyStringProp

  log "endsWith & endsWith'"
  let
    endsWith'LengthProp :: String -> String -> Result
    endsWith'LengthProp search str =
      endsWith' search (Data.String.length str) str === endsWith search str

  quickCheck endsWith'LengthProp

  log "escapeRegex"
  assert $ escapeRegex "."   === "\\."
  assert $ escapeRegex "*"   === "\\*"
  assert $ escapeRegex "+"   === "\\+"
  assert $ escapeRegex "?"   === "\\?"
  assert $ escapeRegex "^"   === "\\^"
  assert $ escapeRegex "$"   === "\\$"
  assert $ escapeRegex "{"   === "\\{"
  assert $ escapeRegex "}"   === "\\}"
  assert $ escapeRegex "("   === "\\("
  assert $ escapeRegex ")"   === "\\)"
  assert $ escapeRegex "|"   === "\\|"
  assert $ escapeRegex "["   === "\\["
  assert $ escapeRegex "]"   === "\\]"
  assert $ escapeRegex "-"   === "\\-"
  assert $ escapeRegex "\\"  === "\\\\"
  assert $ escapeRegex "A-Z" === "A\\-Z"

  log "filter"
  let
    filterIdProp :: String -> Result
    filterIdProp str = filter (const true) str === str

    filterNukeProp :: String -> Result
    filterNukeProp str = filter (const false) str === ""

    filterIdempotenceProp :: (String -> Boolean) -> String -> Result
    filterIdempotenceProp f str = filter f (filter f str) === filter f str

    filterDistributiveProp :: (String -> Boolean) -> String -> String -> Result
    filterDistributiveProp f a b =
      filter f (a <> b) === filter f a <> filter f b

    filterEmptyStringProp :: (String -> Boolean) -> Result
    filterEmptyStringProp f = filter f "" === ""

    allButPureScript :: String -> Boolean
    allButPureScript "ℙ" = true
    allButPureScript "∪" = true
    allButPureScript "𝕣" = true
    allButPureScript "ⅇ" = true
    allButPureScript "Ⴝ" = true
    allButPureScript "𝚌" = true
    allButPureScript "𝕣" = true
    allButPureScript "ⅈ" = true
    allButPureScript "𝚙" = true
    allButPureScript "†" = true
    allButPureScript _ = false

  -- This assertion is to make sure that `filter` operates on code points
  -- and not code units.
  assert $ filter allButPureScript "ℙ∪𝕣ⅇႽ𝚌𝕣ⅈ𝚙† rocks!" === "ℙ∪𝕣ⅇႽ𝚌𝕣ⅈ𝚙†"
  quickCheck filterIdProp
  quickCheck filterIdempotenceProp
  quickCheck filterDistributiveProp
  quickCheck filterEmptyStringProp
  quickCheck filterNukeProp

  log "fromCharArray"
  let
    fromCharArrayIdProp :: String -> Result
    fromCharArrayIdProp = (===) <$> fromCharArray <<< toCharArray <*> id
  assert $
    fromCharArray ["ℙ", "∪", "𝕣", "ⅇ", "Ⴝ", "𝚌", "𝕣", "ⅈ", "𝚙", "†"]
      === "ℙ∪𝕣ⅇႽ𝚌𝕣ⅈ𝚙†"
  quickCheck fromCharArrayIdProp

  log "includes"
  let
    includesSubsetProp :: String -> Result
    includesSubsetProp str = includes str str === true

    includesEmptyStringProp :: String -> Result
    includesEmptyStringProp str = includes "" str === true

  assert $ includes "Merchant" "The Merchant of Venice" === true
  assert $ includes "Duncan" "The Merchant of Venice" === false
  quickCheck includesSubsetProp
  quickCheck includesEmptyStringProp

  log "includes'"
  let
    includes'SubsetProp :: String -> Result
    includes'SubsetProp str = includes' str 0 str === true

    includes'EmptyStringProp :: String -> Int -> Result
    includes'EmptyStringProp str pos = includes' "" pos str === true

    includes'NegativePositionProp :: String -> NegativeInt -> String -> Result
    includes'NegativePositionProp needle (NegativeInt n) haystack =
      includes' needle n haystack === includes' needle 0 haystack

  assert $ includes' "𝟙𝟚𝟛" 1 "𝟘𝟙𝟚𝟛𝟜𝟝𝟞𝟟𝟠𝟡" === true
  assert $ includes' "𝟙𝟚𝟛" 2 "𝟘𝟙𝟚𝟛𝟜𝟝𝟞𝟟𝟠𝟡" === false
  assert $ includes' "𝟡"  10 "𝟘𝟙𝟚𝟛𝟜𝟝𝟞𝟟𝟠𝟡" === false
  quickCheck includes'SubsetProp
  quickCheck includes'EmptyStringProp
  quickCheck includes'NegativePositionProp

  log "includes s == includes' s 0"
  let
    includesZeroProp :: String -> String -> Result
    includesZeroProp searchTerm =
      (===) <$> includes searchTerm <*> includes' searchTerm 0

  quickCheck includesZeroProp

  log "length"
  let
    lengthNonNegativeProp :: String -> Result
    lengthNonNegativeProp str = length str >= 0 === true

  assert $ length "" === 0
  assert $ length "ℙ∪𝕣ⅇႽ𝚌𝕣ⅈ𝚙†" === 10
  quickCheck lengthNonNegativeProp

  log "lines"
  let
    linesNewlineProp :: NewlineChar -> Result
    linesNewlineProp (NewlineChar c) =
      lines ("Action" <> c' <> "is" <> c' <> "eloquence.")
        === ["Action", "is", "eloquence."]
      where
        c' = Data.String.singleton c

  -- The CRLF case has to be tested separately due to it using two chars
  assert $ lines "Action\r\nis\r\neloquence." === ["Action", "is", "eloquence."]
  quickCheck linesNewlineProp

  log "mapChars"
  -- Mapping over individual characters (Unicode code points) in e.g.
  -- unnormalized strings results in unexpected (yet correct) behaviour.
  assert $ mapChars (const "x") "Åström" === "xxxxxxxx"

  log "normalize"
  -- Due to incomplete fonts, the strings in the following assertions may
  -- appear to be different from one another.
  -- They are canonically equivalent, however.

  -- Å: U+00C5
  -- Å: U+212B
  assert $ normalize "Å" === normalize "Å"

  -- Åström: U+00C5        U+0073 U+0074 U+0072 U+00F6        U+006D
  -- Åström: U+0041 U+030A U+0073 U+0074 U+0072 U+006F U+0308 U+006D
  assert $ normalize "Åström" === normalize "Åström"

  -- á: U+00E1
  -- á: U+0061 U+0301
  assert $ normalize "á" === normalize "á"

  -- Amélie: U+0041 U+006d U+00e9        U+006c U+0069 U+0065
  -- Amélie: U+0041 U+006d U+0065 U+0301 U+006c U+0069 U+0065
  assert $ normalize "Amélie" === normalize "Amélie"

  -- ḱṷṓn: U+1E31 U+1E77 U+1E53                             U+006E
  -- ḱṷṓn: U+006B U+0301 U+0075 U+032D U+006F U+0304 U+0301 U+006E
  assert $ normalize "ḱṷṓn" === normalize "ḱṷṓn"

  log "normalize & normalize'"
  let
    nfcProp :: String -> Result
    nfcProp = (===) <$> normalize <*> normalize' NFC

  quickCheck nfcProp

  log "repeat"
  let
    repeatZeroProp :: String -> Result
    repeatZeroProp str = repeat 0 str === Just ""

    repeatOnceProp :: String -> Result
    repeatOnceProp = (===) <$> repeat 1 <*> Just

    repeatNegativeProp :: NegativeInt -> String -> Result
    repeatNegativeProp (NegativeInt n) str = repeat n str === Nothing

    repeatEmptyStringProp :: NonNegativeInt -> Result
    repeatEmptyStringProp (NonNegativeInt n) = repeat n "" === Just ""

  assert $ repeat 3 "𝟞" === Just "𝟞𝟞𝟞"
  assert $ repeat 2147483647 "𝟞" === Nothing
  quickCheck repeatZeroProp
  quickCheck repeatOnceProp
  quickCheck repeatNegativeProp
  quickCheck repeatEmptyStringProp

  log "replaceAll"
  let
    replaceAllIdProp :: String -> String -> Result
    replaceAllIdProp old str = replaceAll old old str === str

  assert $ replaceAll "." "" "Q.E.D." === "QED"
  quickCheck replaceAllIdProp

  log "startsWith"
  let
    startsWithSubsetProp :: String -> Result
    startsWithSubsetProp str = startsWith str str === true

    startsWithEmptyStringProp :: String -> Result
    startsWithEmptyStringProp str = startsWith "" str === true

  assert $ startsWith "Pure"   "PureScript" === true
  assert $ startsWith "Script" "PureScript" === false
  quickCheck startsWithSubsetProp
  quickCheck startsWithEmptyStringProp

  log "startsWith'"
  let
    -- Note that negative `position` arguments have the same effect as `0`
    -- Cf. http://www.ecma-international.org/ecma-262/6.0/#sec-string.prototype.startswith
    startsWith'EmptyStringProp :: String -> Int -> Result
    startsWith'EmptyStringProp str n = startsWith' "" n str === true

  assert $ startsWith' "Script" 4 "PureScript" === true
  assert $ startsWith' "Pure"   4 "PureScript" === false
  quickCheck startsWith'EmptyStringProp

  log "startsWith & startsWith'"
  let
    startsWith'ZeroProp :: String -> String -> Result
    startsWith'ZeroProp searchString str =
      startsWith' searchString 0 str === startsWith searchString str

  quickCheck startsWith'ZeroProp

  log "stripChars"
  let
    stripCharsIdempotenceProp :: String -> String -> Result
    stripCharsIdempotenceProp chars =
      (===) <$> (stripChars chars <<< stripChars chars) <*> stripChars chars

    stripCharsEmptyStringProp :: String -> Result
    stripCharsEmptyStringProp = (===) <$> id <*> stripChars ""

  assert $ stripChars "Script"     "JavaScript" === "Java" -- Seriously?
  assert $ stripChars "PURESCRIPT" "purescript" === "purescript"
  assert $ stripChars "a-z"        "-abc--xyz-" === "bcxy"
  quickCheck stripCharsIdempotenceProp
  quickCheck stripCharsEmptyStringProp

  log "stripDiacritics"
  assert $ stripDiacritics "Ångström"        === "Angstrom"
  assert $ stripDiacritics "Crème Brulée"    === "Creme Brulee"
  assert $ stripDiacritics "Götterdämmerung" === "Gotterdammerung"
  assert $ stripDiacritics "ℙ∪𝕣ⅇႽ𝚌𝕣ⅈ𝚙†"      === "ℙ∪𝕣ⅇႽ𝚌𝕣ⅈ𝚙†"
  assert $ stripDiacritics "Raison d'être"   === "Raison d'etre"
  assert $ stripDiacritics "Týr"             === "Tyr"
  assert $ stripDiacritics "Zürich"          === "Zurich"

  log "toCharArray"
  let
    toCharArrayFromCharArrayIdProp :: String -> Result
    toCharArrayFromCharArrayIdProp =
      (===) <$> fromCharArray <<< toCharArray <*> id

  assert $ toCharArray "" === []
  assert $
    toCharArray "ℙ∪𝕣ⅇႽ𝚌𝕣ⅈ𝚙†"
      === ["ℙ", "∪", "𝕣", "ⅇ", "Ⴝ", "𝚌", "𝕣", "ⅈ", "𝚙", "†"]

  quickCheck toCharArrayFromCharArrayIdProp

  log "unsafeCodePointAt"
  assert $ unsafeCodePointAt  0 "a"          === 97
  assert $ unsafeCodePointAt  0 "ab"         === 97
  assert $ unsafeCodePointAt  1 "ab"         === 98
  assert $ unsafeCodePointAt  0 "∀"          === 8704
  assert $ unsafeCodePointAt  1 "∀ε"         === 949
  assert $ unsafeCodePointAt  0 "𝟘𝟙𝟚𝟛𝟜𝟝𝟞𝟟𝟠𝟡" === 120792
  assert $ unsafeCodePointAt  1 "𝟘𝟙𝟚𝟛𝟜𝟝𝟞𝟟𝟠𝟡" === 120793

  log "unsafeCodePointAt'"
  assert $ unsafeCodePointAt'  0 "a"          === 97
  assert $ unsafeCodePointAt'  0 "ab"         === 97
  assert $ unsafeCodePointAt'  1 "ab"         === 98
  assert $ unsafeCodePointAt'  0 "∀"          === 8704
  assert $ unsafeCodePointAt'  1 "∀ε"         === 949
  assert $ unsafeCodePointAt'  0 "𝟘𝟙𝟚𝟛𝟜𝟝𝟞𝟟𝟠𝟡" === 120792
  assert $ unsafeCodePointAt'  1 "𝟘𝟙𝟚𝟛𝟜𝟝𝟞𝟟𝟠𝟡" === 57304
  assert $ unsafeCodePointAt' 19 "𝟘𝟙𝟚𝟛𝟜𝟝𝟞𝟟𝟠𝟡" === 57313

  log "unsafeRepeat"
  let
    unsafeRepeatZeroProp :: String -> Result
    unsafeRepeatZeroProp str = unsafeRepeat 0 str === ""

    unsafeRepeatOnceProp :: String -> Result
    unsafeRepeatOnceProp = (===) <$> unsafeRepeat 1 <*> id

    unsafeRepeatEmptyStringProp :: NonNegativeInt -> Result
    unsafeRepeatEmptyStringProp (NonNegativeInt n) = unsafeRepeat n "" === ""

  assert $ unsafeRepeat 3 "𝟞" === "𝟞𝟞𝟞"
  quickCheck unsafeRepeatZeroProp
  quickCheck unsafeRepeatOnceProp
  quickCheck unsafeRepeatEmptyStringProp

  log "words"
  let
    wordsWhiteSpaceProp :: WhiteSpaceChar -> Result
    wordsWhiteSpaceProp (WhiteSpaceChar c) =
      words ("Action" <> c' <> "is" <> c' <> "eloquence.")
        === ["Action", "is", "eloquence."]
      where
        c' = Data.String.singleton c

  quickCheck wordsWhiteSpaceProp
