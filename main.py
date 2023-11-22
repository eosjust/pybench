import os
import sys
import time
import json
from concurrent.futures import ProcessPoolExecutor, wait, as_completed
from slither.slither import Slither


# def fib(n):
#     if n <= 2:
#         return 1
#     return fib(n - 1) + fib(n - 2)

def fib(n):
    for i in range(1, 5000000):
        i = i * 1000
    return n


def chk(n):
    workDir = "contracts/" + str(n) + "/"
    extArgs = {}
    extArgs['solc_working_dir'] = workDir
    settings = {}
    with open(workDir + "settings.json", 'r') as f:
        settings = json.load(f)
    extArgs['solc_solcs_select'] = settings.get('ver', None)
    remaps = settings.get('remap', None)
    if remaps is not None:
        extArgs['solc_remaps'] = remaps
    optim = settings.get('optim', None)
    if optim is not None:
        extArgs['solc_args'] = '--optimize --optimize-runs ' + optim
    mainPath = settings['mainPath']
    if mainPath.startswith('/'):
        mainPath = mainPath[1:len(mainPath)]
    slither = Slither(
        mainPath,
        **extArgs
    )
    contracts = []
    for contract in slither.contracts_derived:
        contracts.append(contract.name)
    contract_num = len(contracts)
    return str(n) + ":" + str(contract_num)


def execute_process():
    executor = ProcessPoolExecutor(max_workers=1)
    numbers = list(range(1, 100))
    futures = []
    for num in numbers:
        task = executor.submit(fib, num)
        futures.append(task)
    start = time.time()
    # wait(futures)

    # for num, future in zip(numbers, futures):
    #     print(f'fib({num}) = {future.result()}')
    for future in as_completed(futures):
        data = future.result()
        print(f"main: {data}")
    print(f'COST: {time.time() - start}')


def exe_process2(loop_cnt, thread_cnt, log_detail):
    executor = ProcessPoolExecutor(max_workers=thread_cnt)
    numbers = list(range(1, 100))
    futures = []
    for lp in list(range(0, loop_cnt)):
        for num in numbers:
            task = executor.submit(chk, num)
            futures.append(task)
    start = time.time()
    # wait(futures)
    # for num, future in zip(numbers, futures):
    #     print(f'fib({num}) = {future.result()}')
    if log_detail == 1:
        for future in as_completed(futures):
            data = future.result()
            print(f"main: {data}")
    else:
        wait(futures)
    print(f'COST: {time.time() - start}')


if __name__ == '__main__':
    print('arg lens:', len(sys.argv))
    loop_cnt = 1
    thread_cnt = 4
    log_detail = 1
    if len(sys.argv) == 2:
        thread_cnt = int(sys.argv[1])
    if len(sys.argv) == 3:
        loop_cnt = int(sys.argv[1])
        thread_cnt = int(sys.argv[2])
    if len(sys.argv) == 4:
        loop_cnt = int(sys.argv[1])
        thread_cnt = int(sys.argv[2])
        log_detail = int(sys.argv[3])
    exe_process2(loop_cnt, thread_cnt, log_detail)

# extArgs={}
# slither = Slither(
#     'FEGexPRO.sol',
#     solc_solcs_select='0.8.7',
#     **extArgs
# )
