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
    function Mutate(solução,prob::Float64)
        if(rand()<prob)
            return swap_elements(solução)
        end
        return solução 
    end
    function AG(G, N::Int, L::Int, seed::Int, num_pop::Int, num_passos::Int,prob::Float64)
        Random.seed!(seed)
        população = generate_pop(N, num_pop, L)
        Aptidão = zeros(num_pop)
        tempo = 0
        for i in 1:num_pop
            Aptidão[i] = objetivo(G, população[i, :])
        end
        
        t = 0
        tempo = 0
        x = []
        y = []
        while t != num_passos
            tempo += @elapsed begin
                sorting = shuffle(collect(1:num_pop))
                
                pais = sorting[1:4]
                indices_dois_maiores = sortperm(Aptidão[sorting[1:4]], rev = true)[1:2]
                pais = pais[indices_dois_maiores]
                novo = Descendentes(view(população, pais, :), view(Aptidão, pais), L, "max")
                novo = Mutate(novo,prob)
                site = argmin(Aptidão)
                população[site, :] .= novo
                Aptidão[site] = objetivo(G, população[site, :])
                
                t += 1
                if abs(mean(Aptidão) - maximum(Aptidão)) < 1e-6
                    break
                end
            end
            push!(x,tempo)
            push!(y,maximum(Aptidão))
        end
        
        
        return x,y,maximum(Aptidão),tempo
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
        return x,y,Aptidão,tempo
    end

    function resfriamento(T,alpha)
        return T/(1+alpha*T)
    end

    function SimulatedAnneling(G, N::Int, L::Int, seed::Int,check::Int,k::Int,T::Int,alpha::Float64)
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
                probabilidade = exp(-(Aptidão_vizinha - Aptidão)/T)
                T = resfriamento(T,alpha)
                if Aptidão_vizinha > Aptidão || probabilidade <= rand()
                    população = solução_vizinha
                    Aptidão = Aptidão_vizinha
                end
                if(length(y) > 200)
                    media1 = mean(y[end-99:end])
                    media2 = mean(y[end-199:end])
                    if (abs(media1 - media2) < 1e-6)
                        break
                    end
                end
                
            end
            push!(x,tempo)
            push!(y,Aptidão)
        end
        return x,y,Aptidão,tempo
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
    
        
        vetor1 = vec(range(300, step=50, stop=600))
        vetor2 = vec(range(4000, step=500, stop=6000))
        vetor3 = vec([0.01,0.05,0.1,0.0])
        arquivo = open("./output/best_AG.txt", "a")
        L = 40
    
        Threads.nthreads() > 1 || error("Julia não está configurado para usar threads.")
    
        combinacoes = collect(Iterators.product(vetor1, vetor2,vetor3))
        @threads for comb in combinacoes
            local melhor = 0
            local x = 1
            local result = 0
            tasks = Task[]
            for seed in 1:20
                N = 100 
                p = 0.5 
                rede = criar_rede_erdos_renyi(N, p, 42 * x + seed)
    
                t = Threads.@spawn  AG(rede, N, L, 42 * x + seed, comb[1], comb[2],comb[3])
    
                push!(tasks, t)
            end
    
            for t in tasks
                result = fetch(t)
                melhor += result
            end
    
            melhor /= 20
            x += 1
            println(arquivo,comb,"\t", melhor)
            println("$comb\t$melhor")
        end
    end
    function best_SA()
    
        
        vetor1 = [1, 2]
        vetor2 = vec(range(1, step=5, stop=25))
        vetor3 = vec(range(1000, step=1000, stop=6000))
        vetor4 = [0.01,0.1,0.5,0.6,0.7,0.8,0.9]

        arquivo = open("./output/best_SA.txt", "a")
        L = 40
    
        Threads.nthreads() > 1 || error("Julia não está configurado para usar threads.")
    
        combinacoes = collect(Iterators.product(vetor1, vetor2,vetor3,vetor4))
        rodou = 1
        @threads for comb in combinacoes
            local melhor = 0
            local x = 1
            local result = 0
            tasks = Task[]
            for seed in 1:20
                N = 100 
                p = 0.5 
                rede = criar_rede_erdos_renyi(N, p, 42 * x + seed)
    
                t = Threads.@spawn  SimulatedAnneling(rede, N, L, 42 * x + seed, comb...)[4]
    
                push!(tasks, t)
            end
    
            for t in tasks
                result = fetch(t)
                melhor += result
            end
    
            melhor /= 20
            x += 1
            println(arquivo,comb,"\t", melhor)
            rodou += 1
            println(rodou,"/",length(combinacoes))
        end
    end

    function compara()
        N = 100  # Número de vértices
        p = 0.5  # Probabilidade de criação de uma aresta
        arquivo = open("./output/best_tempo.txt", "a")
        L = 40

        # Configuração de threads
        Threads.nthreads() > 1 || error("Julia não está configurado para usar threads.")
        tam = 1000
        ag_results = Vector{Any}(undef, tam)
        #ls_results = Vector{Any}(undef, tam)
        x = 2

        Threads.@threads for seed in 1:tam
            rede = criar_rede_erdos_renyi(N, p, 42 * x + seed)
            t = Threads.@spawn LocalSearch(rede, N, L, 42* x + seed, 1, 21)[4]
            #t = Threads.@spawn AG(rede, N, L, 42 * x + seed, 300, 6000,0.01)[2]
            #t = Threads.@spawn SimulatedAnneling(rede, N, L, 42 * x + seed, 1, 21,5000,0.5)[4]
            ag_results[seed] = fetch(t)
        end
        
        for seed in 1:tam
            println(arquivo, x, "\t", ag_results[seed])
        end

        #= Threads.@threads for seed in 1:tam
            rede = criar_rede_erdos_renyi(N, p, 93 * x + seed)
            t = Threads.@spawn LocalSearch(rede, N, L, 93 * x + seed, 2, 20)[3]
            ls_results[seed] = fetch(t)
        end

        for seed in 1:tam
            println(arquivo, x, "\t", ls_results[seed])
        end =#
    end
    function get_best()
        arquivo = open("./output/best_SA.txt", "r")
        valores = readlines(arquivo)
        close(arquivo)
        grafico = vec([])
        for i in valores
            x = split(i,"\t")
            push!(grafico,vec([x[1],parse(Float64, x[2])]))
        end
        coluna = [p[2] for p in grafico]
        println(grafico[sortperm(coluna, rev=true)][1,:])
    end
end
