//
//  DownloadDataWithCombine.swift
//  handsOnCombine
//
//  Created by Matheus Zanivan on 28/02/23.
//

import Foundation
import Combine


struct GatoModel : Identifiable, Codable  {
	let id, url: String

	enum CodingKeys: String, CodingKey {
		case id = "_id"
		case url
	}
}




/*
URL:  https://cataas.com/cat?html=true&json=true
estrutura:
 {
   "tags": [
	 "laying",
	 "white_fur",
	 "multiple_colors"
   ],
   "createdAt": "2020-03-21T20:29:08.582Z",
   "updatedAt": "2022-10-11T07:52:32.439Z",
   "validated": true,
   "owner": "null",
   "file": "5e7679148012e50018706879.jpeg",
   "mimetype": "image/jpeg",
   "size": 182371,
   "_id": "kF7tVxvQa3zjW7wP",
   "url": "/cat/kF7tVxvQa3zjW7wP"
 }
 */
// Historiazinha pra explicar:
/*
 1 - Fazer a assinatura da revista de esporte para as revisata chegar para você
 2 - a editora recebe dados para fazer a revista, e vai fazer uma nova edição
 3 - Você recebe a ultima edição da revista
 4 - Voce verifica se a revista não está danificada
 5 - Você abre a revista e verifica se o conteúdo da revista está correto, se realmente é uma revista de esporte
 6 - Você lê a revista
 7 - Você pode cancelar a assinatura a qualquer momento
 
 1 - criamos a publisher
 2 - subscrevemos a publisher em uma background thread
 3 - recebe na thread main
 4 - tryMap (verifica se os dados estao corretos)
 5 - decode (decode dos dados na struct gatos)
 6 - sink (colocar o item no nosso app)
 7 - store (cancelar a assinatura se quisermos)
 */

class DownloadDataWithCombine : ObservableObject{
	@Published var gato : GatoModel = GatoModel(id: "", url: "")
	
	var cancellables = Set<AnyCancellable>()
	//7
	//basicamente esse aqui é o lugar que a gente vai guardar essa publisher, entao se a gente quiser cancelar isso aqui no futuro a gente pode acessar essa variavel e depois pedir para cancelar
	
	init(){
		 getCat()
	}
	
	func getCat(){
		
		//quando a gente cria essa url aqui, ela é opcional entao a gente tem que tem certeza que é uma url válida ai usamos o guardLet
		guard let url = URL(string: "https://cataas.com/cat?html=true&json=true") else { return }
		
        // Além de criar uma variável do tipo URL e tratar seu valor opcional com o guard let, podemos utilizar uma outra estrutura, chama de urlComponents, onde podemos "desmembrar" nossa URL em diversos componentes, veja uma adptação da nossa url da cat API usando o urlComponents:
        var urlComponents = URLComponents()
        
        urlComponents.scheme = "https"
        urlComponents.host = "cataas.com"
        urlComponents.path = "/cat"
        urlComponents.queryItems = [URLQueryItem(name: "html", value: "true"), URLQueryItem(name: "json", value: "true")]
        
//        guard let url = urlComponents.url else { return }
        
//        print("url criada através do guard let: \(url)")
//        print("url criada através do urlComponents: \(urlComponents.url!)")
        
		
		//nessa parte falamos de que é aqui que a gente vai usar o combine, e explicamos com a analogia da revista
		
		//1
		//nessa parte criamos urlsession .shared.dataTask e procuramos por publishers
		//pelo fato de ser uma publisher sabemos que ela vai trazer dados com o tempo
		URLSession.shared.dataTaskPublisher(for: url)
		
		//2
		//no nosso caso ja é feito por padrao na dataTaskPublisher (background thread) então não necessariamente precisariamos passar pelo numero 2
		//mas vamos fazer mesmo assim, pois algumas publishers que voce cria não ficam por padrão na thread de background, então é importante saber fazer isso
			.subscribe(on: DispatchQueue.global(qos: .background))
		//explicação sobre threads: em um app a gente tem várias threads que a gente pode executar tarefas, e quase todo código que vc vai escrever, vai ser declarado na thread main (que é a thread 1) a não ser que voce declare em outra thread
		// a thread main ela consegue lidar com bastante coisa, mas se você for desenvolver algo mais parrudo no seu app é importante você dividir as tarefas entre as threads para evitar que o seu app trave
		//e o mais importante para saber sobre threading é lembrar que qualquer coisa que atualiza a UI precisa ser feito na thread principal
		//3
		
		//entao aqui nessa linha a gente joga pra thread main, pq é aonde a UI pode ser atualizada
			.receive(on: DispatchQueue.main)
		
		//4
		//tryMap é um map que pode falhar e retornar um erro
		//aqui temos o input que é o 'data' que é esses dados que estao chegando em potencial
		//basicamente a gente tem um input que nesse caso é nossos supostos dados
		//e a gente quer retornar com algum objeto entao a gente vai fazer um retorno do tipo Data
		
			.tryMap { (data, response) -> Data in
				//a primeira coisa que a gente quer fazer é pegar esse response e checar se ele é um http url response e se é uma response válida
				guard
					let response = response as? HTTPURLResponse,
					response.statusCode >= 200 && response.statusCode < 300 else {
					throw URLError(.badServerResponse)
				}
				return data
					  //basicamente chegamos se estão vindo os dados normalmente e se estamos daremos return desses dados
			}
		
		//5
		//entao agora que a gente tem esses dados a gente tem que ter certeza que São mesmo gatos que estão vindo
		//aqui podemos observar que o tipo é decodable.protocol .decode(type: <#T##Decodable.Protocol#>), entao se a gente dar uma olhada na nossa struct Gatos ela é codable
		//entao basicamente deixa a gente dar incode ou decode de dados json na nossa struct
		//entao a gente pode usar o Gatos aqui
			.decode(type: GatoModel.self, decoder: JSONDecoder())
		//6
		//aqui no sink a gente vai usar finalmente usar o dado que a gente ta recebendo
		
			.sink { (completion) in
				//isso aqui tambem vai falar pra gente que se teve um erro vai voltar um como failed
				switch completion{
				case .finished:
					print("Deu Certo")
				case .failure(let error):
					print("Erro: \(error)")
				}
				//mas se for bem sucedida, nós vamos receber um valor do tipo gatoModel
			} receiveValue: { [weak self] (returnedGato) in
				//criar primeiro uma referencia forte, colocando apenas self.gato = returnedGato não usar o [weak self]
				//isso cria uma referencia forte para o self, e tem situacoes no nosso app que a gente nao quer uma referencia forte porque isso vai manter o self na memória quando a gente nao quer ou simplesmente nao precisa
				//entao pra arrumar isso a gente tem que adicionar o [weak self] aqui e deixar o self opicional
				self?.gato = returnedGato
			}
		//7
			.store(in: &cancellables)

		
	}
}



