//
//  NoteViewControllerDelegate.swift
//  Notes
//
//  Created by Huy Bui on 2022-11-25.
//

import Foundation

protocol NoteViewControllerDelegate: AnyObject {
    func generateNoteFileName()
    func saveNote(_ text: String)
}
