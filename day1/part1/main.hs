main = do
  contents <- readFile "input"
  print . sum . map calculateRequiredFuel . map readInt . lines $ contents

calculateRequiredFuel :: Integral a => a -> a
calculateRequiredFuel x = x `div` 3 - 2

readInt :: String -> Int
readInt = read
