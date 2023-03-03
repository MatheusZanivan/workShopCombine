//
//  ContentView.swift
//  handsOnCombine
//
//  Created by Matheus Zanivan on 27/02/23.
//

import SwiftUI

struct ContentView: View {
	
	@ObservedObject var vm = DownloadDataWithCombine()
	@State var gatinhoAtual = "https://cataas.com/"
	var body: some View {
		
		AsyncImage(url: URL(string: gatinhoAtual)){ image in
			image
				.resizable()
				.aspectRatio(contentMode: .fill)
			
		} placeholder: {
			Color.gray
		}
		
		Button("Carregar gato"){
			gatinhoAtual = "https://cataas.com/\(vm.gato.url)"
		}
		
	}
}


struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
