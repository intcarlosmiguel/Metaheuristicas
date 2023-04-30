import numpy as np
from scipy.optimize import minimize

def KPS(x,V,P):
    return np.dot(x,V),np.dot(x,P)

def generate_população(Valor,Peso,Mochila,tipo = 'aleatorio'):
    if(tipo == 'aleatorio'):
         #Geração da População
        população = np.random.randint(0,2,size = (int(2**6),len(Peso)))

        #Garantia que o caso [0,0,...,0] esteja
        while(0 in np.sum(população,axis = 1)):
            população = np.random.randint(0,2,size = (int(2**6),len(Peso)))
        return população
    elif(tipo == 'baseado'):
        #Será gerado uma população aleatória
        população = generate_população(Valor,Peso,Mochila,tipo = 'aleatorio')

        #Para cada organismo
        for i in população:

            _, P  = KPS(i,Valor,Peso)

            # Se for uma solução inválida geraremos um número aleatório e retiramos o item da mochila
            while(P > Mochila):
                r = np.random.randint(0,len(Peso),size = 1)[0]
                i[r] = 0
                _, P  = KPS(i,Valor,Peso)
        return população
    else:
        print('Digitou errado!')

def Cruzamento(população,Valor,Peso,tipo):
    descendentes = []
    if(tipo == '1corte'):

        for i in range(0,len(população),2):
            lamb = np.random.randint(0,len(Peso),size = 1)[0]
            descendentes.append([np.concatenate((população[i][:lamb],população[i+1][lamb:])),np.concatenate((população[i+1][:lamb],população[i][lamb:]))])
        
        descendentes = np.array([ j for i in descendentes for j in i])
        return descendentes
    elif(tipo == '2corte'):
        
        for i in range(0,len(população),2):
            lamb = np.random.randint(0,len(Peso),size = 2)
            while(lamb[0] != lamb[1]):
                lamb = np.random.randint(0,len(Peso),size = 2)
            corte1 = np.min(lamb)
            corte2 = np.max(lamb)
            descendente1 = np.concatenate((população[i][:corte1],população[i+1][corte1:corte2],população[i][corte2:]))
            descendente2 = np.concatenate((população[i+1][:corte1],população[i][corte1:corte2],população[i+1][corte2:]))
            descendentes.append([descendente1,descendente2])
        
        descendentes = np.array([ j for i in descendentes for j in i])
        return descendentes
    elif(tipo == 'aleatorio'):
        
        for i in range(0,len(população),2):
            parent1 = população[i]
            parent2 = população[i+1]
            descendente1,descendente2 = np.array([[i,j] if(np.random.rand() > 0.5) else [j,i] for i,j in zip(parent1,parent2)]).T
            descendentes.append([descendente1,descendente2])
        
        descendentes = np.array([ j for i in descendentes for j in i])
        return descendentes
    elif(tipo == 'probabilistico'):

        for i in range(0,len(população),2):
            parent1 = população[i]
            parent2 = população[i+1]

            Q1,_ = KPS(população[i],Valor,Peso)
            Q2,_ = KPS(população[i+1],Valor,Peso)
            descendente1,descendente2 = np.array([[i,j] if(np.random.rand() < Q1/(Q1+Q2)) else [j,i] for i,j in zip(parent1,parent2)]).T
            descendentes.append([descendente1,descendente2])
        
        descendentes = np.array([ j for i in descendentes for j in i])
        return descendentes
    else:
        print('Digitou errado!')

def Cruzamento(população,Valor,Peso, Mochila,tipo):
    descendentes = []
    if(tipo == '1corte'):

        for i in range(0,len(população),2):
            lamb = np.random.randint(0,len(Peso),size = 1)[0]
            descendentes.append([np.concatenate((população[i][:lamb],população[i+1][lamb:])),np.concatenate((população[i+1][:lamb],população[i][lamb:]))])
        
        descendentes = np.array([ j for i in descendentes for j in i])
        return descendentes
    elif(tipo == '2corte'):
        
        for i in range(0,len(população),2):
            lamb = np.random.randint(0,len(Peso),size = 2)
            while(lamb[0] != lamb[1]):
                lamb = np.random.randint(0,len(Peso),size = 2)
            corte1 = np.min(lamb)
            corte2 = np.max(lamb)
            descendente1 = np.concatenate((população[i][:corte1],população[i+1][corte1:corte2],população[i][corte2:]))
            descendente2 = np.concatenate((população[i+1][:corte1],população[i][corte1:corte2],população[i+1][corte2:]))
            descendentes.append([descendente1,descendente2])
        
        descendentes = np.array([ j for i in descendentes for j in i])
        return descendentes
    elif(tipo == 'aleatorio'):
        
        for i in range(0,len(população),2):
            parent1 = população[i]
            parent2 = população[i+1]
            descendente1,descendente2 = np.array([[i,j] if(np.random.rand() > 0.5) else [j,i] for i,j in zip(parent1,parent2)]).T
            descendentes.append([descendente1,descendente2])
        
        descendentes = np.array([ j for i in descendentes for j in i])
        return descendentes
    elif(tipo == 'probabilistico'):

        for i in range(0,len(população),2):
            parent1 = população[i]
            parent2 = população[i+1]

            Q1,_ = KPS(população[i],Valor,Peso)
            Q2,_ = KPS(população[i+1],Valor,Peso)
            descendente = np.array([i if(np.random.rand() < Q1/(Q1+Q2)) else j for i,j in zip(parent1,parent2)]).T
            _,P = KPS(descendente,Valor,Peso)
            if(P < Mochila):
                descendentes.append(descendente)
        descendentes = np.array(descendentes)
        return descendentes
    else:
        print('Digitou Errado!')

def Atualização(população,descentes,Valor,Peso,Mochila,tipo):
    if(tipo == 'elitista'):
        Qualidade,_ = KPS(população,Valor,Peso)
        população = população[np.argsort(Qualidade)]
        população[:descentes.shape[0]] = descentes
        return população
    if(tipo == 'incremental'):

        Qualidade,P = KPS(descentes,Valor,Peso)
       # print(Qualidade,P)
        if(len( Qualidade[P<Mochila])!= 0):
            Qualidade = Qualidade[P<Mochila]
        melhor_descendente = descentes[np.argsort(Qualidade)[::-1]][0]

        Qualidade,_ = KPS(população,Valor,Peso)
        pior_parent  = np.argsort(Qualidade)[0]

        população[pior_parent] = melhor_descendente
        return população
    else:
        print('Digitou errado!')

def KPSresposta(Valor, Peso, Mochila):
    # Definindo os parâmetros do problema da mochila
    values = Valor # valores dos objetos
    weights = Peso # pesos dos objetos
    capacity = Mochila # capacidade da mochila

    # Definindo a função objetivo e as restrições
    def objective(x):
        return -sum([v * x[i] for i, v in enumerate(values)])

    def constraint(x):
        return capacity - sum([w * x[i] for i, w in enumerate(weights)])

    # Definindo os limites das variáveis
    bounds = [(0, 1) for i in range(len(values))]

    # Resolvendo o problema da mochila
    solution = minimize(objective, x0=[0]*len(values), bounds=bounds, constraints={'type': 'ineq', 'fun': constraint})

    # Imprimindo a solução
    print("Objetivo: ", -solution.fun) # negativo porque a função objetivo foi definida como a soma negativa dos valores
    print("Itens na mochila: ", [i+1 for i in range(len(values)) if solution.x[i] > 0.5]) # selecionando os itens que foram escolhidos