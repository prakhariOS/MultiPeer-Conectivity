//
//  TodoViewController.swift
//  Multipeer_demo
//
//  Created by prakhar gupta on 14/03/22.
//

import UIKit
import MultipeerConnectivity

///
///
///
class TodoViewController: UIViewController, MCBrowserViewControllerDelegate
{
    /// Represents a peer in a multipeer session.
    var peerID:MCPeerID!
    /// Facilitates communication among all peers.
    var mcSession:MCSession!
    /// Presents incoming invitations to the user and handles user's responses.
    var mcAdvertiserAssistant:MCAdvertiserAssistant!
    
    /// A todo tableview.
    @IBOutlet private var todoTableView: UITableView!

    /// A todo Items.
    var todoItems:[TodoItem]!
}

// MARK: - Overrides
extension TodoViewController
{
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.todoTableView.dataSource = self

        self.loadData()
    
        
        
        self.peerID = MCPeerID(displayName: UIDevice.current.name)
        self.mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        self.mcSession.delegate = self
        
        
        
        
    }
}


// MARK: - Helper methods
extension TodoViewController
{
    ///
    /// Loading the items data.
    ///
    private func loadData()
    {
        self.todoItems = [TodoItem]()
        self.todoItems = DataManager.loadAll(TodoItem.self).sorted(by: {$0.createdAt < $1.createdAt})
        self.todoTableView.reloadData()
    }
    
    private func sendTodo (_ todoItem:TodoItem)
    {
        if mcSession.connectedPeers.count > 0
        {
            if let todoData = DataManager.loadData(todoItem.itemIdentifier.uuidString)
            {
                do
                {
                    try mcSession.send(todoData, toPeers: mcSession.connectedPeers, with: .reliable)
                }
                catch
                {
                    fatalError("Could not send todo item")
                }
            }
        }
        else
        {
            print("you are not connected to another device")
        }
    }
}


// MARK: - Actions
extension TodoViewController
{
    @IBAction private func addTodoAction(_ sender: Any)
    {
        let addAlert = UIAlertController(title: "New Todo", message: "Enter a title", preferredStyle: .alert)
        addAlert.addTextField { (textfield:UITextField) in
            textfield.placeholder = "ToDo Item Title"
        }
        
        addAlert.addAction(UIAlertAction(title: "Create", style: .default, handler: { (action:UIAlertAction) in
            guard let title = addAlert.textFields?.first?.text else {return}
            let newTodo = TodoItem(title: title, completed: false, createdAt: Date(), itemIdentifier: UUID())
            newTodo.saveItem()
            self.todoItems.append(newTodo)
            
            let indexPath = IndexPath(row: self.todoTableView.numberOfRows(inSection: 0), section: 0)
            
            self.todoTableView.insertRows(at: [indexPath], with: .automatic)
        }))
        
        addAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(addAlert, animated: true, completion: nil)
    }

    @IBAction private func connectivityAction(_ sender: Any)
    {
        let actionSheet = UIAlertController(title: "ToDo Exchange", message: "Do you want to Host or Join a session?", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Host Session", style: .default, handler: { (action:UIAlertAction) in
            
            self.mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "ba-td", discoveryInfo: nil, session: self.mcSession)
            self.mcAdvertiserAssistant.start()
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Join Session", style: .default, handler: { (action:UIAlertAction) in
            let mcBrowser = MCBrowserViewController(serviceType: "ba-td", session: self.mcSession)
            mcBrowser.delegate = self
            self.present(mcBrowser, animated: true, completion: nil)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
}


// MARK: - Table view data source
extension TodoViewController: UITableViewDataSource
{
    func numberOfSections(in tableView: UITableView) -> Int
    {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return todoItems.count
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath) as! ItemCell

        let todoItem = self.todoItems[indexPath.row]
        cell.titleLabel.text = todoItem.title
        cell.delegte = self

        return cell
    }
}


// MARK: - Todo cell delegate.
extension TodoViewController: TodoCellDelegate
{
    func didRequestDelete(_ cell: ItemCell)
    {
        if let indexPath = self.todoTableView.indexPath(for: cell)
        {
            self.todoItems[indexPath.row].deleteItem()
            self.todoItems.remove(at: indexPath.row)
            self.todoTableView.deleteRows(at: [indexPath], with: .automatic)
            
        }
    }
    
    
    func didRequestShare(_ cell: ItemCell)
    {
        if let indexPath = self.todoTableView.indexPath(for: cell)
        {
            let todoItem = todoItems[indexPath.row]
            self.sendTodo(todoItem)
        }
    }
}

// MARK: - MCSessionDelegate delegate.
extension TodoViewController: MCSessionDelegate
{
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState)
    {
        switch state
        {
        case MCSessionState.connected: print("Connected: \(peerID.displayName)")
            
        case MCSessionState.connecting: print("Connecting: \(peerID.displayName)")
            
        case MCSessionState.notConnected: print("Not Connected: \(peerID.displayName)")
        @unknown default: print("error")
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID)
    {
        do
        {
            let todoItem = try JSONDecoder().decode(TodoItem.self, from: data)
            
            DataManager.save(todoItem, with: todoItem.itemIdentifier.uuidString)
            
            DispatchQueue.main.async
            {
                self.todoItems.append(todoItem)
                
                let indexPath = IndexPath(row: self.todoTableView.numberOfRows(inSection: 0), section: 0)
                
                self.todoTableView.insertRows(at: [indexPath], with: .automatic)
            }
            
        }
        catch
        {
            fatalError("Unable to process recieved data")
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID)
    {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress)
    {
        
    }

    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?)
    {
        
    }

    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController)
    {
        dismiss(animated: true, completion: nil)
    }

    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController)
    {
        dismiss(animated: true, completion: nil)
    }
}
