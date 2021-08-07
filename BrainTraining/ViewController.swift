//
//  ViewController.swift
//  BrainTraining
//
//  Created by Satish Bandaru on 07/08/21.
//

import UIKit
import Vision

struct Question {
    var text: String
    var correct: Int
    var actual: Int?
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var questions = [Question]()
    var score = 0
    var digitsModel = Digits()

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var drawView: DrawingImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Brain Training"
        tableView.layer.borderColor = UIColor.lightGray.cgColor
        tableView.layer.borderWidth = 1
        drawView.delegate = self
        askQuestion()
    }

    func numberDrawn(_ image: UIImage) {
        let modelSize = 299
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: modelSize, height: modelSize),
                                               true, 1.0)
        image.draw(in: CGRect(x: 0, y: 0, width: modelSize, height: modelSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        guard let ciImage = CIImage(image: newImage) else {
            fatalError("Failed to convert UIImage to CIImage")
        }
        
        guard let model = try? VNCoreMLModel(for: digitsModel.model) else {
            fatalError("Failed to prepare model for Vision")
        }
        
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation],
                  let firstPrediction = results.first else {
                fatalError("Failed to make a prediction: \(error?.localizedDescription ?? "Unknown error")")
            }
            
            var secondPrediction: VNClassificationObservation?
            if results.count >= 2 {
                secondPrediction = results[1]
            }
            
            DispatchQueue.main.async {
                let firstPredictionResult = Int(firstPrediction.identifier) ?? 0
                let secondPredictionResult = Int(secondPrediction?.identifier ?? "") ?? 0
                
                if self?.questions[0].correct == firstPredictionResult {
                    self?.score += 1
                    self?.questions[0].actual = firstPredictionResult
                } else if self?.questions[0].correct == secondPredictionResult {
                    self?.score += 1
                    self?.questions[0].actual = secondPredictionResult
                } else {
                    self?.questions[0].actual = firstPredictionResult
                }
                
                self?.askQuestion()
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage)
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([request])
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func setText(for cell: UITableViewCell, at indexPath: IndexPath, to question: Question) {
        if indexPath.row == 0 {
            cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 48)
        } else {
            cell.textLabel?.font = UIFont.systemFont(ofSize: 17)
        }
        
        if let actual = question.actual {
            cell.textLabel?.text = "\(question.text) = \(actual)"
        } else {
            cell.textLabel?.text = "\(question.text) = ?"
        }
    }
    
    func restartGame(action: UIAlertAction) {
        score = 0
        questions.removeAll()
        tableView.reloadData()
        askQuestion()
    }
    
    func createQuestion() -> Question {
        var question = ""
        var correctAnswer = 0
        
        while true {
            let firstNumber = Int.random(in: 0...9)
            let secondNumber = Int.random(in: 0...9)
            
            if Bool.random() == true {
                let result = firstNumber + secondNumber
                
                if result < 10 {
                    question = "\(firstNumber) + \(secondNumber)"
                    correctAnswer = result
                    break
                }
            } else {
                let result = firstNumber - secondNumber
                
                if result >= 0 {
                    question = "\(firstNumber) - \(secondNumber)"
                    correctAnswer = result
                    break
                }
            }
        }
        
        return Question(text: question, correct: correctAnswer, actual: nil)
    }
    
    func askQuestion() {
        if questions.count == 20 {
            let ac = UIAlertController(title: "Game over!",
                                       message: "You scored \(score)/20.",
                                       preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "Play again", style: .default, handler: restartGame))
            ac.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(ac, animated: true)
            return
        }
        
        // clear any previous iamge
        drawView.image = nil
        
        // create a question and insert it into our array so that it appears at the top of the table
        questions.insert(createQuestion(), at: 0)
        
        let newIndexPath = IndexPath(row: 0, section: 0)
        tableView.insertRows(at: [newIndexPath], with: .right)
        
        // try to find the second cell in our table; this was the top cell a moment ago, and needs to be changed
        let secondIndexPath = IndexPath(row: 1, section: 0)
        if let cell = tableView.cellForRow(at: secondIndexPath) {
            // update this cell so that it shows the user's answer in the correct font
            setText(for: cell, at: secondIndexPath, to: questions[1])
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return questions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let currentQuestion = questions[indexPath.row]
        setText(for: cell, at: indexPath, to: currentQuestion)
        return cell
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
}
