main = do
    contents <- readFile "input"
    print . sum . map rf. map readInt . lines $ contents


tm :: Integral a => a -> a
tm x | ffm x <= 0 = x
     | otherwise  = x + tm(ffm x)

ffm :: Integral a => a -> a
ffm x = x `div` 3 - 2

rf :: Integral a => a -> a
rf x = tm x - x

readInt :: String -> Int
readInt = read
