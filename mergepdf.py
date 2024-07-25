#!/usr/bin/env python3

import os
import PyPDF3

def main():
    filelist = os.listdir(input())
    filelist.sort()
    print(filelist)
    exit
    merger = PyPDF3.PdfFileMerger()

    for i in filelist:
        pathroot, ext = os.path.splitext(i)
        if ext == '.pdf':
            merger.append(i)

    merger.write('./merger.pdf')
    merger.close()

if __name__ == '__main__':
    main()
