import os
import sys
import time
from slither.slither import Slither

st = time.time()
slither = Slither(
    './FEGexPRO.sol',
    solc_solcs_select='0.8.7',
)
ed = time.time()
cost = ed-st
print(cost)