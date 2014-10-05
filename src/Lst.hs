module Lst where

import Prelude hiding (takeWhile)
import qualified Text.Show.Pretty as Pretty
import Text.Parsec.Combinator
import Text.Parsec.Prim hiding ((<|>))
import Control.Applicative hiding (many)
import Modifications
import Common

-- custom lst types
import Lst.Skill(SkillDefinition)
import Lst.Language(LanguageDefinition)
import Lst.WeaponProf(WeaponProficency)
import Lst.ShieldProf(ShieldProficency)
import Lst.ArmorProf(ArmorProficency)
import Lst.Domain(DomainDefinition)
import Lst.Equipment(EquipmentDefinition)

-- generic, catch-all
import Lst.Generic(LSTDefinition)

-- structure of a lst file
data LST a = Source [Header]
           | Definition a
           | Comment String deriving Show

-- source headers: these are found in nearly every lst file type.
data Header = SourceLong String
            | SourceShort String
            | SourceWeb String
            | SourceDate String deriving Show

parseSourceWeb :: PParser Header
parseSourceWeb = SourceWeb <$> (tag "SOURCEWEB" >> restOfTag)

parseSourceLong :: PParser Header
parseSourceLong = SourceLong <$> (tag "SOURCELONG" >> restOfTag)

parseSourceShort :: PParser Header
parseSourceShort = SourceShort <$> (tag "SOURCESHORT" >> restOfTag)

parseSourceDate :: PParser Header
parseSourceDate = SourceDate <$> (tag "SOURCEDATE" >> restOfTag)

parseHeaders :: PParser [Header]
parseHeaders = header `sepBy1` tabs where
  header = parseSourceLong
       <|> parseSourceShort
       <|> parseSourceWeb
       <|> parseSourceDate

parseLSTLines :: PParser a -> PParser [LST a]
parseLSTLines parseDefinition = do
  _ <- many eol
  many1 $ lstLine <* many eol where
    lstLine = Source <$> parseHeaders
          <|> Comment <$> parseCommentLine
          <|> Definition <$> parseDefinition

parseLST :: Show a => PParser (LSTLine a) -> FilePath -> IO [LST (LSTLine a)]
parseLST lstPParser lstName  = do
  contents <- readContents lstName
  return $ parseResult fullPParser lstName contents where
    fullPParser = parseLSTLines lstPParser

-- debugging only
prettyPrint :: Show a => PParser (LSTLine a) -> FilePath -> IO String
prettyPrint = showAll . parseLST where
  showAll = ((Pretty.ppShow <$>) .)

parseLSTToString :: String -> FilePath -> IO String
parseLSTToString "LANGUAGE" = prettyPrint (parseLSTLine :: PParser (LSTLine LanguageDefinition))
parseLSTToString "ARMORPROF" = prettyPrint (parseLSTLine :: PParser (LSTLine ArmorProficency))
parseLSTToString "SHIELDPROF" = prettyPrint (parseLSTLine :: PParser (LSTLine ShieldProficency))
parseLSTToString "WEAPONPROF" = prettyPrint (parseLSTLine :: PParser (LSTLine WeaponProficency))
parseLSTToString "SKILL" = prettyPrint (parseLSTLine :: PParser (LSTLine SkillDefinition))
parseLSTToString "DOMAIN" = prettyPrint (parseLSTLine :: PParser (LSTLine DomainDefinition))
parseLSTToString "EQUIPMENT" = prettyPrint (parseLSTLine :: PParser (LSTLine EquipmentDefinition))
parseLSTToString _ = prettyPrint (parseLSTLine :: PParser (LSTLine LSTDefinition))
