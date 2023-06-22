include("funcoes.jl")


#= arquivo = open("./output/best_AG.txt", "r")
valores = readlines(arquivo)
close(arquivo)
grafico = vec([])
for i in valores
    x = split(i,"\t")
    push!(grafico,vec([x[1],parse(Float64, x[2])]))
end
coluna = [p[2] for p in grafico]
println(grafico[sortperm(coluna, rev=true)]) =#
N = 100  # Número de vértices
p = 0.5  # Probabilidade de criação de uma aresta
arquivo = open("./output/best.txt", "a")
L = 40

# Configuração de threads
Threads.nthreads() > 1 || error("Julia não está configurado para usar threads.")



x = 1

tasks = Task[]
Threads.@threads for seed in 1:100
    rede = criar_rede_erdos_renyi(N, p, 42 * x + seed)

    t = Threads.@spawn  AG(rede, N, L, 42 * x + seed, 100, 400)
    push!(tasks, t)

end
for i in 1:100
    println(arquivo,x,"\t", tasks[i])
end
tasks = Task[]
x += 1
Threads.@threads for seed in 1:100
    rede = criar_rede_erdos_renyi(N, p, 93 * x + seed)

    t = Threads.@spawn  LS(rede, N, L, 93 * x + seed, 2, 20)[3]
    push!(tasks, t)

end
for i in 1:100
    println(arquivo,x,"\t", tasks[i])
end