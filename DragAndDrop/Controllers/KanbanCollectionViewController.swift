//
//  KanbanCollectionViewController.swift
//  DragAndDrop
//
//  Created by Khurram Shahzad on 17/03/2021.
//

import UIKit
import MobileCoreServices

class KanbanCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {

    // MARK: - iVars
    
    var boards = [
        BoardModel(title: "Concept", items: ["Data Collection", "Data Analysis", "System Analysis"]),
        BoardModel(title: "In Review", items: ["Designing the System"]),
        BoardModel(title: "Approved", items: ["Coding the System", "Quality Analysis"]),
        BoardModel(title: "Completed", items: ["Budget"]),
    ]
    
    // MARK: - ViewLifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationBar()
        updateCollectionViewItem(with: view.bounds.size)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateCollectionViewItem(with: size)
    }
    
    // MARK: - Helper Methods
    
    private func setupNavigationBar() {
        setupAddButtonItem()
    }
    
    private func updateCollectionViewItem(with size: CGSize) {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        layout.itemSize = CGSize(width: size.width - 68, height: size.height * 0.75)
    }
    
    func setupAddButtonItem() {
        let addButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addListTapped(_:)))
        navigationItem.rightBarButtonItem = addButtonItem
    }

    @objc func addListTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Add List", message: nil, preferredStyle: .alert)
        alertController.addTextField(configurationHandler: nil)
        alertController.addAction(UIAlertAction(title: "Add", style: .default, handler: { (_) in
            guard let text = alertController.textFields?.first?.text, !text.isEmpty else {
                return
            }
            
            self.boards.append(BoardModel(title: text, items: []))
            
            let addedIndexPath = IndexPath(item: self.boards.count - 1, section: 0)
            
            self.collectionView.insertItems(at: [addedIndexPath])
            self.collectionView.scrollToItem(at: addedIndexPath, at: UICollectionView.ScrollPosition.centeredHorizontally, animated: true)
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true)
    }
    
    // MARK: UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return boards.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! KanbanCollectionViewCell
        
        cell.setup(with: boards[indexPath.item])
        cell.parentVC = self
        return cell
    }
    
}

// MARK: - UIDropInteractionDelegate

extension KanbanCollectionViewController: UIDropInteractionDelegate {
    
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        return UIDropProposal(operation: .move)
    }
    
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        
        if session.hasItemsConforming(toTypeIdentifiers: [kUTTypePlainText as String]) {
            session.loadObjects(ofClass: NSString.self) { (items) in
                guard let _ = items.first as? String else {
                    return
                }
                
                if let (dataSource, sourceIndexPath, tableView) = session.localDragSession?.localContext as? (BoardModel, IndexPath, UITableView) {
                    tableView.beginUpdates()
                    dataSource.items.remove(at: sourceIndexPath.row)
                    tableView.deleteRows(at: [sourceIndexPath], with: .automatic)
                    tableView.endUpdates()
                }
            }
        }
    }
}
