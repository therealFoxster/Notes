//
//  NoteViewController.swift
//  Notes
//
//  Created by Huy Bui on 2022-11-25.
//

import UIKit

class NoteViewController: UIViewController {
    
    @IBOutlet var note: UITextView!
    
    var delegate: NoteViewControllerDelegate!
    var initialText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.largeTitleDisplayMode = .never
        
        // Text view.
        let horizontalInset: CGFloat = 20
        note.contentInset.left = horizontalInset
        note.contentInset.right = horizontalInset
        note.text = initialText
        
        // Adjust text view to accommodate keyboard.
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustTextViewForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustTextViewForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Toolbar items.
        let deleteNoteButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteNote)),
            flexibleSpace = UIBarButtonItem(systemItem: .flexibleSpace),
            createNoteButton = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(createNote))
        deleteNoteButton.tintColor = .systemRed
        createNoteButton.tintColor = .systemOrange
        
        toolbarItems = [deleteNoteButton, flexibleSpace, createNoteButton]
        navigationController?.isToolbarHidden = false
        
        // Navigation item.
        let shareButton = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareNote))
        navigationItem.rightBarButtonItem = shareButton
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if isMovingFromParent {
            // Popped from navigation controller.
            if initialText != note.text { // New text/text changed.
                delegate.saveNote(note.text ?? "")
            }
        }
    }
    
    @objc func adjustTextViewForKeyboard(notification: Notification) {
        // Grab keyboard's frame after it's finished animating (keyboardFrameEndUserInfoKey).
        // from notification information dictionary (userInfo).
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        // keyboardValue is an NSValue object that wraps a CGRect structure (dictionaries can't contain structure so NSValue wrapper was required).
        
        // Pull CGRect structure from keyboardValue.
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        
        // Convert rectangle to view's coordinates to fix width & height flipped when in landscape.
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        // Keyboard disappearing.
        if notification.name == UIResponder.keyboardWillHideNotification {
            note.contentInset.bottom = .zero
        }
        
        // Keyboard appearing.
        else {
            note.contentInset.bottom = keyboardViewEndFrame.height - view.safeAreaInsets.bottom
        }
        
        // Prevent scroll indicator from scrolling underneath the keyboard.
        note.scrollIndicatorInsets = note.contentInset
        
        let selectedRange = note.selectedRange
        note.scrollRangeToVisible(selectedRange) // Scroll until cursor is visible.
    }
    
    @objc func shareNote() {
        let activityViewController = UIActivityViewController(activityItems: [note.text ?? ""], applicationActivities: [])
        activityViewController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(activityViewController, animated: true)
    }
    
    @objc func deleteNote() {
        note.text = "" // Emptying note so it will be ignored (deleted) in delegate's saveNote().
        navigationController?.popViewController(animated: true)
    }
    
    @objc func createNote() {
        note.text = ""
        delegate.generateNoteFileName()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
