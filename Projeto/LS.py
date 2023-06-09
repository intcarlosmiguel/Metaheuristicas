import networkx as nx
import numpy as np
import matplotlib.pyplot as plt
from AG import *
from IPython.display import clear_output

def swap_elements(arr):
    # Escolhe aleatoriamente dois índices diferentes
    idx1, idx2 = True, True
    while(idx1 == idx2):
        idx1, idx2 = np.random.choice(len(arr), 2, replace=True)
    
    # Realiza o swap dos elementos
    arr[idx1], arr[idx2] = arr[idx2], arr[idx1]
    
    return arr
def reorder(arr):
    arr2 = np.copy(arr)
    np.random.shuffle(arr2)
    return arr2

def vizinhança(G,solução_inicial,objetivo,check = 'swap',k = 5):
    if(check == 'swap'):
        solução_vizinha = np.array([swap_elements(solução_inicial) for i in range(k)])
    if(check == 'reorder'):
        solução_vizinha = np.array([reorder(solução_inicial) for i in range(k)])
    Aptidão2 = np.array([objetivo(G,i) for i in solução_vizinha])
    sorting = np.argsort(Aptidão2)[::-1]
    return solução_vizinha[sorting[0]],Aptidão2[sorting[0]]
def LocalSearch(G,N,L,objetivo,seed,check = 'reorder'):
    solução_inicial = generate_inicial(N,1,L)[0]
    s = []
    Aptidão = objetivo(G,solução_inicial)
    cancel = 0
    for i in range(1000):
        np.random.seed(i+seed)
        solução_vizinha, Aptidão2 = vizinhança(G,solução_inicial,objetivo,check)
        if(Aptidão2 > Aptidão):
            solução_inicial = solução_vizinha
            Aptidão = Aptidão2
            cancel = 0
        else:
            if(cancel == 250):
                break
            cancel += 1
        s.append([i,Aptidão])
        if(i%10) == 0:
            clear_output(wait=True)
            print(i)
    s = np.array(s)
    return s