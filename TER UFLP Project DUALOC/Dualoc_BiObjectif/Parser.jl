function parser(fileToOpen::String)
    fileDirectory = "Données/"*fileToOpen
    file = open(fileDirectory)
    line = readlines(file)
    nbClient = parse(Int64,line[1])
    nbService = parse(Int64,line[2])

     c1 = Array{Int64,2}(undef,nbService,nbClient)
     c2 = Array{Int64,2}(undef,nbService,nbClient)

     indLignec1 = 3
     indlignec2 = 4+nbClient
     for i in 1:nbClient
      tabLignec1 = split(line[i+indLignec1]," ")
      tabLignec2 = split(line[i+indlignec2]," ")
       for j in 1:nbService
          c1[j,i] = parse(Int64,tabLignec1[j])+1
          c2[j,i] = parse(Int64,tabLignec2[j])+1
        end
     end

    f1 = Array{Int64,1}(undef,nbService)
    f2 = Array{Int64,1}(undef,nbService)


    indF1 = (2*nbClient)+6
     indF2 = (2*nbClient)+8

    tabLignef1 = split(line[indF1]," ")
    tabLignef2 = split(line[indF2]," ")

     for i in 1:nbService
        f1[i] = parse(Int64,tabLignef1[i])
        f2[i] = parse(Int64,tabLignef2[i])
      end
      c = [c1,c2]
      f = [f1,f2]
    return c,f
end