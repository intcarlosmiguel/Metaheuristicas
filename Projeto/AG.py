import networkx as nx
import numpy as np
import matplotlib.pyplot as plt
from IPython.display import clear_output
import multiprocessing
def Descendentes(pais,obj,L,check = 'min'):
    p = 1 - obj/np.sum(obj) if(check == 'min') else obj/np.sum(obj)
    Descendente = []
    for i,j in zip(pais[0],pais[1]):
        Descendente.append(i if(np.random.rand()< p[0]) else j)
    Descendente = np.array(Descendente)
    if(np.sum(Descendente) > L):
        return Descendentes(pais,obj,L,check)
    return Descendente

def generate_inicial(N,num_pop,L):

    população_inicial = np.random.choice([True, False], size=(num_pop,N))

    for i in range(num_pop):
        while(np.sum(população_inicial[i]) > L):
            população_inicial[i][np.random.randint(N)] = False
        while(np.sum(população_inicial[i]) < L):
            população_inicial[i][np.random.randint(N)] = True
    
    return população_inicial
    

def AG(G,N,L,objetivo,seed,num_pop = 200,num_passos = 1000):
    np.random.seed(seed)
    população = generate_inicial(N,num_pop,L)
    
    grafico = []
    t = 0
    site = 0
    sitios = []

    Aptidão = np.array([objetivo(G,i) for i in população])
    while(t != num_passos):

        #sorting = np.argsort(Aptidão)[::-1]
        sorting = np.arange(len(Aptidão))
        np.random.shuffle(sorting)
        pais = sorting[:2]

        novo = Descendentes(população[pais] ,Aptidão[pais],L,'max')

        site = np.argsort(Aptidão)[0]
        população[site] = novo
        Aptidão[site] = objetivo(G,população[site])

        t += 1
        grafico.append([t,np.mean(Aptidão),np.max(Aptidão)])
        #clear_output(wait=True)
        #print(t)
        if(np.abs(np.mean(Aptidão) - np.max(Aptidão)) < 1e-6):
            
            break
    return np.array(grafico).T, np.max(Aptidão)

def generate_all_data(i):
    N = 100
    #n = 20
    #L = 20
    G = nx.erdos_renyi_graph(N, 0.5)
    x = []
    s = 0
    for j in range(7):
        grafico,sitios = AG(G,N,i,objetivo,100*i+j,100,4000)
        s += sitios
    x.append([i,s/N])
    x = np.array(x)
    try:
        conteudo_existente = np.loadtxt("./resultados.txt")
    except OSError:
        conteudo_existente = np.array([])

    # Concatenar o conteúdo existente com o novo array
    dados_completos = np.concatenate((conteudo_existente, x))
    np.savetxt("./resultados.txt", dados_completos, fmt="%d")
    return grafico

def processamento():


# Crie um pool de processos com 10 processos
    with multiprocessing.Pool(processes=10) as pool:
    # Mapeie as tarefas para o pool de processos
        pool.map(generate_all_data, range(5,101,5) )