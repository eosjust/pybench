import os
import lzma as xz
import gzip
import dill
import marshal

def save_object_to_zip(objects, filename,algo):
    # if not os.path.exists(filename):
    #     file_path = os.path.split(filename)[0]
    #     if file_path and not os.path.exists(file_path):  # 需要文件夹
    #         os.mkdir(os.path.split(filename)[0])  # 创建文件夹
    #     os.mknod(filename)  # 创建文件
    fil = None
    if algo=='gzip':
        fil = gzip.open(filename+"."+algo, 'wb')
    elif algo=='lzma':
        fil = xz.open(filename+"."+algo, 'wb')
    else:
        fil = open(filename+".bin",'wb')
    dill.dump(objects, fil)
    fil.close()

def load_object_from_zip(filename,algo):
    fil = None
    if algo=='gzip':
        fil = gzip.open(filename+"."+algo, 'rb')
    elif algo=='lzma':
        fil = xz.open(filename+"."+algo, 'rb')
    else:
        fil = open(filename+".bin",'rb')
    obj = dill.load(fil)
    fil.close()
    return obj