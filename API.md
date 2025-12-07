#Video Streaming
import Foundation

let headers = [
	"x-rapidapi-key": "33fe9f1a18msh5f0b640ad83fa5fp19fe7djsnc8186c835ebc",
	"x-rapidapi-host": "musclewiki-api.p.rapidapi.com"
]

let request = NSMutableURLRequest(url: NSURL(string: "https://musclewiki-api.p.rapidapi.com/stream/videos/branded/male-Barbell-barbell-curl-front.mp4")! as URL,
                                        cachePolicy: .useProtocolCachePolicy,
                                    timeoutInterval: 10.0)
request.httpMethod = "GET"
request.allHTTPHeaderFields = headers

let session = URLSession.shared
let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
	if (error != nil) {
		print(error as Any)
	} else {
		let httpResponse = response as? HTTPURLResponse
		print(httpResponse)
	}
})

dataTask.resume()

#Media

## Videos
import Foundation

let headers = [
	"x-rapidapi-key": "33fe9f1a18msh5f0b640ad83fa5fp19fe7djsnc8186c835ebc",
	"x-rapidapi-host": "musclewiki-api.p.rapidapi.com"
]

let request = NSMutableURLRequest(url: NSURL(string: "https://musclewiki-api.p.rapidapi.com/media/videos/branded/%7Bvideo%7D")! as URL,
                                        cachePolicy: .useProtocolCachePolicy,
                                    timeoutInterval: 10.0)
request.httpMethod = "GET"
request.allHTTPHeaderFields = headers

let session = URLSession.shared
let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
	if (error != nil) {
		print(error as Any)
	} else {
		let httpResponse = response as? HTTPURLResponse
		print(httpResponse)
	}
})

dataTask.resume()

##Bodymap
import Foundation

let headers = [
	"x-rapidapi-key": "33fe9f1a18msh5f0b640ad83fa5fp19fe7djsnc8186c835ebc",
	"x-rapidapi-host": "musclewiki-api.p.rapidapi.com"
]

let request = NSMutableURLRequest(url: NSURL(string: "https://musclewiki-api.p.rapidapi.com/media/images/bodymaps/%7Bbodymap%7D")! as URL,
                                        cachePolicy: .useProtocolCachePolicy,
                                    timeoutInterval: 10.0)
request.httpMethod = "GET"
request.allHTTPHeaderFields = headers

let session = URLSession.shared
let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
	if (error != nil) {
		print(error as Any)
	} else {
		let httpResponse = response as? HTTPURLResponse
		print(httpResponse)
	}
})

dataTask.resume()
