{-# LANGUAGE OverloadedStrings #-}
module Main (main) where

import System.Environment (getArgs)
import System.Exit (exitWith, ExitCode (..))
import System.Directory (createDirectoryIfMissing, doesFileExist)
import System.FilePath ((</>))
import Data.Aeson (decode, (.:), withObject, FromJSON (..))
import qualified Data.ByteString.Lazy as BL

import Measure (discoverAndMeasure)
import Canonical (writePretty)

data Sidecar = Sidecar { sRemote :: String, sScannedAt :: String }

instance FromJSON Sidecar where
  parseJSON = withObject "Sidecar" $ \o ->
    Sidecar <$> o .: "remote" <*> o .: "scanned_at"

main :: IO ()
main = do
  args <- getArgs
  case args of
    [fixtureDir, outputDir] -> do
      createDirectoryIfMissing True outputDir
      let sidecarPath = fixtureDir </> ".glossfero-fixture.json"
      exists <- doesFileExist sidecarPath
      if not exists
        then do
          putStrLn ("missing sidecar: " ++ sidecarPath)
          exitWith (ExitFailure 1)
        else do
          raw <- BL.readFile sidecarPath
          case decode raw :: Maybe Sidecar of
            Nothing -> do
              putStrLn "sidecar is not valid JSON matching {remote, scanned_at}"
              exitWith (ExitFailure 1)
            Just sc -> do
              record <- discoverAndMeasure fixtureDir (sRemote sc) (sScannedAt sc)
              writePretty (outputDir </> "repo_record.json") record
    _ -> do
      putStrLn "usage: conformance-cli <fixture-dir> <output-dir>"
      exitWith (ExitFailure 2)
