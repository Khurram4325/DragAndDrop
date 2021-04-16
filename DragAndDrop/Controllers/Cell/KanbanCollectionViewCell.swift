//
//  KanbanCollectionViewCell.swift
//  DragAndDrop
//
//  Created by Khurram Shahzad on 17/03/2021.
//

import UIKit
import MobileCoreServices

class KanbanCollectionViewCell: UICollectionViewCell {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - iVars
    
    weak var parentVC: KanbanCollectionViewController?
    var board: BoardModel?
    
    // MARK: - CellLifeCycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 10.0
        
        tableView.dragInteractionEnabled = true
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        
        tableView.tableFooterView = UIView()
        tableView.register(UINib(nibName: "KanbanTableViewCell", bundle: nil), forCellReuseIdentifier: "KanbanTableViewCell")
        tableView.register(UINib(nibName: "ListHeaderFooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: "ListHeaderFooterView")
    }
    
    // MARK: - Helper Methods
    
    func setup(with data: BoardModel) {
        self.board = data
        tableView.reloadData()
    }
    
    @IBAction func addTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Add Item", message: nil, preferredStyle: .alert)
        alertController.addTextField(configurationHandler: nil)
        alertController.addAction(UIAlertAction(title: "Add", style: .default, handler: { (_) in
            guard let text = alertController.textFields?.first?.text, !text.isEmpty else {
                return
            }
            
            guard let data = self.board else {
                return
            }
            
            data.items.append(text)
            let addedIndexPath = IndexPath(item: data.items.count - 1, section: 0)
            
            self.tableView.insertRows(at: [addedIndexPath], with: .automatic)
            self.tableView.scrollToRow(at: addedIndexPath, at: UITableView.ScrollPosition.bottom, animated: true)
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        parentVC?.present(alertController, animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension KanbanCollectionViewCell: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return board?.items.count ?? 0
    }
    
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        return board?.title
//    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50.0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "ListHeaderFooterView") as? ListHeaderFooterView else { fatalError("Unexpected found nil.") }
        
        headerView.titleLabel.text = board?.title
        return headerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "KanbanTableViewCell", for: indexPath) as? KanbanTableViewCell else { fatalError("Unexpected found nil.") }
        if let aBoard = board {
            cell.titleLabel.text = "\(aBoard.items[indexPath.row])"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - UITableViewDragDelegate

extension KanbanCollectionViewCell: UITableViewDragDelegate {
    
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard let board = board, let stringData = board.items[indexPath.row].data(using: .utf8) else {
            return []
        }
        
        let itemProvider = NSItemProvider(item: stringData as NSData, typeIdentifier: kUTTypePlainText as String)
        let dragItem = UIDragItem(itemProvider: itemProvider)
        session.localContext = (board, indexPath, tableView)
        
        return [dragItem]
    }
    
    func tableView(_ tableView: UITableView, dragSessionWillBegin session: UIDragSession) {
        self.parentVC?.navigationItem.rightBarButtonItem = nil
    }
    
    func tableView(_ tableView: UITableView, dragSessionDidEnd session: UIDragSession) {
        self.parentVC?.setupAddButtonItem()
        self.parentVC?.navigationItem.leftBarButtonItem = nil
    }
}

// MARK: - UITableViewDropDelegate

extension KanbanCollectionViewCell: UITableViewDropDelegate {
    
    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        if coordinator.session.hasItemsConforming(toTypeIdentifiers: [kUTTypePlainText as String]) {
            coordinator.session.loadObjects(ofClass: NSString.self) { (items) in
                guard let string = items.first as? String else {
                    return
                }
                
                switch (coordinator.items.first?.sourceIndexPath, coordinator.destinationIndexPath) {
                case (.some(let sourceIndexPath), .some(let destinationIndexPath)):
                    // Same Table View
                    let updatedIndexPaths: [IndexPath]
                    if sourceIndexPath.row < destinationIndexPath.row {
                        updatedIndexPaths =  (sourceIndexPath.row...destinationIndexPath.row).map { IndexPath(row: $0, section: 0) }
                    } else if sourceIndexPath.row > destinationIndexPath.row {
                        updatedIndexPaths =  (destinationIndexPath.row...sourceIndexPath.row).map { IndexPath(row: $0, section: 0) }
                    } else {
                        updatedIndexPaths = []
                    }
                    self.tableView.beginUpdates()
                    self.board?.items.remove(at: sourceIndexPath.row)
                    self.board?.items.insert(string, at: destinationIndexPath.row)
                    self.tableView.reloadRows(at: updatedIndexPaths, with: .automatic)
                    self.tableView.endUpdates()
                    break
                    
                case (nil, .some(let destinationIndexPath)):
                    // Move data from a table to another table
                    self.removeSourceTableData(localContext: coordinator.session.localDragSession?.localContext)
                    self.tableView.beginUpdates()
                    self.board?.items.insert(string, at: destinationIndexPath.row)
                    self.tableView.insertRows(at: [destinationIndexPath], with: .automatic)
                    self.tableView.endUpdates()
                    break
                    
                    
                case (nil, nil):
                    // Insert data from a table to another table
                    self.removeSourceTableData(localContext: coordinator.session.localDragSession?.localContext)
                    self.tableView.beginUpdates()
                    self.board?.items.append(string)
                    self.tableView.insertRows(at: [IndexPath(row: self.board!.items.count - 1 , section: 0)], with: .automatic)
                    self.tableView.endUpdates()
                    break
                    
                default: break
                    
                }
            }
        }
    }
    
    func removeSourceTableData(localContext: Any?) {
        if let (dataSource, sourceIndexPath, tableView) = localContext as? (BoardModel, IndexPath, UITableView) {
            tableView.beginUpdates()
            dataSource.items.remove(at: sourceIndexPath.row)
            tableView.deleteRows(at: [sourceIndexPath], with: .automatic)
            tableView.endUpdates()
        }
    }
    
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }
}
