{-# LANGUAGE RecordWildCards #-}

module Choice where

import Text.Parsec.Char (char, string, satisfy)
import Text.Parsec.Combinator (sepBy, many1, notFollowedBy, option)
import Text.Parsec.Prim (try)
import ClassyPrelude hiding (try)

import JEPFormula
import Common

data ChoiceTag = ChooseLanguageTag [ChooseLanguage]
               | ChooseNumberChoicesTag Choices
               | ChooseNumberTag ChooseNumber
               | ChooseManyNumbersTag ChooseManyNumbers
               | ChooseNoChoice ()
               | ChooseSkillTag [ChooseSkill]
               | ChooseEqBuilder EqBuilder
               | ChooseSchools [ChooseSchoolType]
               | ChooseString StringBuilder
               | ChooseUserInput UserInput
               | ChooseEquipment ()
               | ChooseStatBonus ()
               | ChooseSkillBonus ()
               | ChooseWeaponProfBonus ()
                 deriving (Show, Eq)

-- not fully implemented
data ChooseLanguage = ChoiceLanguage String
                    | ChoiceLanguageType String
                      deriving (Show, Eq)

parseChooseLanguage :: PParser [ChooseLanguage]
parseChooseLanguage = do
  _ <- labeled "CHOOSE:LANG|"
  parseChoiceLang `sepBy` char ',' where
    parseChoiceLang = ChoiceLanguageType <$> (labeled "TYPE=" *> parseString)
                  <|> ChoiceLanguage <$> parseString

parseChooseNoChoice :: PParser ()
parseChooseNoChoice = () <$ labeled "CHOOSE:NOCHOICE"

-- not fully implemented
data Choices = Choices { choiceNumber :: Int
                       , choices :: [String]
                       , choiceType :: Maybe String }
                   deriving (Show, Eq)

parseChooseNumChoices :: PParser Choices
parseChooseNumChoices = do
  _ <- labeled "CHOOSE:NUMCHOICES="
  choiceNumber <- textToInt <$> manyNumbers
  choices <- many1 $ try (char '|' *> parseChoiceString)
  choiceType <- tryOption (labeled "|TYPE=" *> parseString)
  return Choices { .. } where
    parseChoiceString = disallowed *> parseString
    disallowed = notFollowedBy (string "TYPE")

-- not fully implemented
-- CHOOSE:NUMBER|v|w|x|y|z
--   not implemented. (NOSIGN/MULTIPLE seems to be undocumented)
data ChooseNumber = ChooseNumber { chooseMin :: Int
                                 , chooseMax :: Int
                                 , chooseTitle :: String }
                    deriving (Show, Eq)

parseChooseNumber :: PParser ChooseNumber
parseChooseNumber = do
  _ <- labeled "CHOOSE:NUMBER"
  chooseMin <- labeled "|MIN=" *> parseInteger
  chooseMax <- labeled "|MAX=" *> parseInteger
  chooseTitle <- labeled "|TITLE=" *> parseStringSemicolon
  return ChooseNumber { .. } where
   parseStringSemicolon = many1 $ satisfy $ inClass "-A-Za-z0-9_ &+,./:?!%#'()[]~;"

data ChooseManyNumbers = ChooseManyNumbers { chooseManyNumbers :: [Int]
                                           , chooseManyMultiple :: Bool
                                           , chooseManyTitle :: String }
                       deriving (Show, Eq)

parseChooseManyNumbers :: PParser ChooseManyNumbers
parseChooseManyNumbers = do
  _ <- labeled "CHOOSE:NUMBER"
  chooseManyNumbers <- parseInteger `sepBy` char '|'
  chooseManyMultiple <- option False (True <$ labeled "MULTIPLE|")
  chooseManyTitle <- labeled "|TITLE=" *> parseString
  return ChooseManyNumbers { .. }

-- not fully implemented
data ChooseSkill = ChoiceSkill String
                 | ChoiceSkillType String
                 | ChoiceSkillTitle String
                   deriving (Show, Eq)

parseChooseSkill :: PParser [ChooseSkill]
parseChooseSkill = do
  _ <- labeled "CHOOSE:SKILL|"
  parseChoiceSkill `sepBy` char '|' where
    parseChoiceSkill = ChoiceSkillType <$> (labeled "TYPE=" *> parseString)
                   <|> ChoiceSkillTitle <$> (labeled "TITLE=" *> parseString)
                   <|> ChoiceSkill <$> parseString

-- CHOOSE:EQBUILDER.SPELL|w|x|y|z
--   w is optional text
--   x is optional spell type (not used)
--   y is optional minimum level
--   z is optional maximum level
data EqBuilder = EqBuilder { eqBuilderText :: Maybe String
                           , eqBuilderMinimumLevel :: Formula
                           , eqBuilderMaximumLevel :: Formula }
               deriving (Show, Eq)

parseChooseEqBuilder :: PParser EqBuilder
parseChooseEqBuilder = do
  _ <- labeled "CHOOSE:EQBUILDER.SPELL"
  eqBuilderText <- tryOption $ char '|' *> parseString <* char '|'
  eqBuilderMinimumLevel <- option (Number 0) $ parseFormula <* char '|'
  eqBuilderMaximumLevel <- option (Variable "MAX_LEVEL") parseFormula
  return EqBuilder { .. }

-- CHOOSE:SCHOOLS|x|x|..
--   x is school name or feat or ALL
data ChooseSchoolType = SchoolName String
                      | FeatName String
                      | AllSchools
                        deriving (Show, Eq)

parseChooseSchools :: PParser [ChooseSchoolType]
parseChooseSchools = labeled "CHOOSE:SCHOOLS|" *> parseSchoolTypes `sepBy` char '|' where
  parseSchoolTypes = (labeled "FEAT=" *> (FeatName <$> parseString))
                 <|> (AllSchools <$ labeled "ALL")
                 <|> (SchoolName <$> parseString)

-- CHOOSE:STRING|x|x..|y
--   x is choice to be offered
--   y is TITLE=text
data StringBuilder = StringBuilder { stringBuilderChoices :: [String]
                                   , stringBuilderTitle :: String }
                   deriving (Show, Eq)

parseChooseString :: PParser StringBuilder
parseChooseString = do
  _ <- labeled "CHOOSE:STRING|"
  stringBuilderChoices <- many1 (parseChoiceString <* char '|')
  stringBuilderTitle <- labeled "TITLE=" *> parseString
  return StringBuilder { .. } where
    parseChoiceString = try $ notFollowedBy (labeled "TITLE=") *> parseString

-- CHOOSE:USERINPUT|x|y
--   x is number of inputs
--   y is chooser dialog title
data UserInput = UserInput { numberOfInputs :: Int
                           , userInputTitle :: String }
                   deriving (Show, Eq)

parseChooseUserInput :: PParser UserInput
parseChooseUserInput = do
  _ <- labeled "CHOOSE:USERINPUT|"
  numberOfInputs <- parseInteger
  userInputTitle <- labeled "TITLE=" *> parseString
  return UserInput { .. }
-- CHOOSE:EQUIPMENT
--   not implemented.
parseChooseEquipment :: PParser ()
parseChooseEquipment = () <$ (labeled "CHOOSE:EQUIPMENT|" >> restOfTag)

-- CHOOSE:STATBONUS|w|x|y|z
--   not implemented.
parseChooseStatBonus :: PParser ()
parseChooseStatBonus = () <$ (labeled "CHOOSE:STATBONUS|" >> restOfTag)

-- CHOOSE:SKILLBONUS|w|x|y|z
--   not implemented.
parseChooseSkillBonus :: PParser ()
parseChooseSkillBonus = () <$ (labeled "CHOOSE:SKILLBONUS|" >> restOfTag)

-- CHOOSE:WEAPONPROFICIENCY|x
--   not implemented (or documented).
parseChooseWeaponProfBonus :: PParser ()
parseChooseWeaponProfBonus = () <$ (labeled "CHOOSE:WEAPONPROFICIENCY|" >> restOfTag)

parseChoice :: PParser ChoiceTag
parseChoice = ChooseLanguageTag <$> parseChooseLanguage
          <|> ChooseNumberChoicesTag <$> parseChooseNumChoices
          -- if this CHOOSE:NUMBER fails, try the next one
          <|> try (ChooseNumberTag <$> parseChooseNumber)
          <|> try (ChooseManyNumbersTag <$> parseChooseManyNumbers)
          <|> ChooseSkillTag <$> parseChooseSkill
          <|> ChooseNoChoice <$> parseChooseNoChoice
          <|> ChooseEqBuilder <$> parseChooseEqBuilder
          <|> ChooseString <$> parseChooseString
          <|> ChooseUserInput <$> parseChooseUserInput
          <|> ChooseSchools <$> parseChooseSchools
          <|> ChooseEquipment <$> parseChooseEquipment
          <|> ChooseStatBonus <$> parseChooseStatBonus
          <|> ChooseSkillBonus <$> parseChooseSkillBonus
          <|> ChooseWeaponProfBonus <$> parseChooseWeaponProfBonus
