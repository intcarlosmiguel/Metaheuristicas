using LightGraphs
using Random
using LightGraphs.SimpleGraphs
using Statistics
using Distributed
using Plots
using Base.Threads
@everywhere begin
    function Descendentes(pais, obj, L, check)
        p = (check == "min") ? (1 - obj / sum(obj)) : (obj / sum(obj))
        Descendente = []
        for (i, j) in zip(pais[1,:], pais[2,:])
            if rand() < p[1]
                push!(Descendente, i)
            else
                push!(Descendente, j)
            end
        end
        
        if sum(Descendente) > L
            return Descendentes(pais, obj, L, check)
        end
        
        return Descendente
    end
    
    function criar_rede_erdos_renyi(n::Int, p::Float64,seed::Int)
        g = SimpleGraph(n)
        Random.seed!(seed)  # Defina uma semente aleatória para reproduzibilidade (opcional)
        
        for i in 1:n
            for j in (i+1):n
                if rand() ≤ p
                    add_edge!(g, i, j)
                end
            end
        end
        
        return g
    end
    
    function objetivo(Grafo, sitio)
        G = copy(Grafo)
        N = nv(G)
        sitios = collect(1:N)
        add_vertex!(G)
        for i in sitios[sitio]
            add_edge!(G,N+1, i)
        end
        centrality = betweenness_centrality(G)
        return minimum(values(centrality))
    end
    
    function swap_elements(array)
        vetor = copy(array)
        indices = randperm(length(vetor))[1:2]
        if vetor[indices[1]] != vetor[indices[2]]
            vetor[indices[1]], vetor[indices[2]] = vetor[indices[2]], vetor[indices[1]]
        else
            return swap_elements(vetor)
        end
        return vetor
    end
    
    function reorder(vetor)
        vetor2 = copy(vetor)
        shuffle!(vetor2)
        return vetor2
    end
    
    function generate_pop(N::Int,num_pop::Int,L::Int)
        população = [rand(Bool) for _ in 1:(N * num_pop)]
    
        população = reshape(população, num_pop, N)
        for i in 1:num_pop
            while (sum(população[i,:]) > L)
    
                população[i, rand(1:N)] = false
            end
            while (sum(população[i,:] )< L)
                população[i, rand(1:N)] = true
            end
        end
        return população
    end
    
    function AG(G, N::Int, L::Int, seed::Int, num_pop::Int, num_passos::Int)
        Random.seed!(seed)
        população = generate_pop(N, num_pop, L)
        Aptidão = zeros(num_pop)
        
        for i in 1:num_pop
            Aptidão[i] = objetivo(G, população[i, :])
        end
        
        t = 0
        while t != num_passos
            sorting = shuffle(collect(1:num_pop))
            
            pais = sorting[1:2]
            novo = Descendentes(view(população, pais, :), view(Aptidão, pais), L, "max")
            
            site = argmin(Aptidão)
            população[site, :] = novo
            Aptidão[site] = objetivo(G, população[site, :])
            
            t += 1
            if abs(mean(Aptidão) - maximum(Aptidão)) < 1e-6
                break
            end
        end
        
        return maximum(Aptidão)
    end
    
    function verificar_vetor(matriz, vetor)
        for linha in matriz
            if all(linha .== vetor)
                return true
            end
        end
        return false
    end
    
    function vizinhança(G,solução_inicial,tabu,check::Int,k::Int)
        solução_vizinha = []
    
        if check == 1
            solução_vizinha  = [vec(swap_elements(solução_inicial)) for i in 1:k]
        else
            solução_vizinha  = [vec(reorder(solução_inicial)) for i in 1:k]
        end
        
        Aptidão = zeros(k)
        for i in 1:k
            Aptidão[i] = objetivo(G, solução_vizinha[i])
            
        end
        sorting = sortperm(Aptidão, rev=true)
        return solução_vizinha[sorting[1]], Aptidão[sorting[1]],tabu
    
    end
    
    function LocalSearch(G, N::Int, L::Int, seed::Int,check::Int,k::Int)
        Random.seed!(seed)
        população = generate_pop(N, 1, L)
        Aptidão = objetivo(G, população[1,:])
        cancel = 0
        x = []
        y = []
        tabu = []
        tempo = 0
        for i in 1:4000
            tempo += @elapsed begin
                solução_vizinha = 0
                Aptidão_vizinha = 0
                if i == 1
                    solução_vizinha,Aptidão_vizinha,tabu = vizinhança(G,população[i,:],tabu,check,k)
                else
                    solução_vizinha,Aptidão_vizinha,tabu = vizinhança(G,população,tabu,check,k)
                end
                if Aptidão_vizinha > Aptidão
                    população = solução_vizinha
                    Aptidão = Aptidão_vizinha
                    cancel = 0
                else
                    if cancel == 200
                        break
                    end
                    cancel += 1
                end
            end
            push!(x,tempo)
            push!(y,Aptidão)
        end
        return x,y,Aptidão
    end
    
    function generate_AG()
        arquivo = open("resultados.txt", "a")
        N = 100  # Número de vértices
        p = 0.5  # Probabilidade de criação de uma aresta
        #L = 10
        total = 20
        for L in range(5, step=5, stop=101)
            x = 0
            for i in 1:total
                rede = criar_rede_erdos_renyi(N, p,42+i)
                x += AG(rede,N,L,42+i,200,4000)
            end
            println(L)
            println(arquivo,L,"\t", x/total)
        end
        close(arquivo)
    end
    
    function plotagem()
        # Abrir o arquivo no modo de leitura
        arquivo = open("resultados.txt", "r")
    
        # Ler e separar os valores
        valores = readlines(arquivo)
        close(arquivo)
        valores = [split(valor, "\t") for valor in valores]
        vetor_floats = map(x -> parse.(Float64, x), valores)
        x = [valor[1] for valor in vetor_floats]
        y = [valor[2]/2 for valor in vetor_floats]
        # Fechar o arquivo
    
    
        # Converter os valores para o tipo desejado, se necessário
        scatter(x,y, size=(800, 600))
        ylabel!("Centralidade")
        xlabel!("# de Ligações")
        savefig("./img/grafico.svg")
    end
    function best_LS()

        # Parâmetros
    
        # Exibir os valores lidos
        vetor1 = [1, 2]
        vetor2 = vec(1:20)
    
        # Configuração de threads
        Threads.nthreads() > 1 || error("Julia não está configurado para usar threads.")
    
        combinacoes = collect(Iterators.product(vetor1, vetor2))
    
        @threads for comb in combinacoes
            local melhor = 0
            local melhor_i = ()
            local x = 1
            local result = 0
    
            tasks = Task[]
    
            for seed in 1:20
                N = 100  # Número de vértices
                p = 0.5  # Probabilidade de criação de uma aresta
                rede = criar_rede_erdos_renyi(N, p, 42)
    
                t = Threads.@spawn LocalSearch(rede, N, 40, 42 * x + seed, comb...)[3]
    
                push!(tasks, t)
            end
    
            for t in tasks
                result = fetch(t)
                melhor += result
            end
    
            melhor /= 20
    
            if melhor > melhor
                melhor = melhor
                melhor_i = comb
            end
    
            x += 1
    
            println("$comb\t$melhor")
        end
    end
    function best_AG()
    
        # Parâmetros
        
        # Exibir os valores lidos
        vetor1 = vec(range(50, step=50, stop=300))
        vetor2 = vec(range(1000, step=500, stop=4000))
        arquivo = open("best_AG.txt", "w")
        L = 40
    
        # Configuração de threads
        Threads.nthreads() > 1 || error("Julia não está configurado para usar threads.")
    
        combinacoes = collect(Iterators.product(vetor1, vetor2))
    
        @threads for comb in combinacoes
            local melhor = 0
            local melhor_i = ()
            local x = 1
            local result = 0
    
            tasks = Task[]
            for seed in 1:20
                N = 100  # Número de vértices
                p = 0.5  # Probabilidade de criação de uma aresta
                rede = criar_rede_erdos_renyi(N, p, 42 * x + seed)
    
                t = Threads.@spawn  AG(rede, N, L, 42 * x + seed, comb[1], comb[2])
    
                push!(tasks, t)
            end
    
            for t in tasks
                result = fetch(t)
                melhor += result
            end
    
            melhor /= 20
    
            if melhor > melhor
                melhor = melhor
                melhor_i = comb
            end
    
            x += 1
            println(arquivo,comb,"\t", melhor)
            println("$comb\t$melhor")
        end
    end

end
