//
//  TableViewController.swift
//  Notes
//
//  Created by Huy Bui on 2022-11-27.
//

import UIKit

class TableViewController: UITableViewController, NoteViewControllerDelegate {

    private var notesDirectoryURL: URL!
    private var noteFilenames: [String] = []
    private var currentNoteFilename = ""
    
    private let noteCountLabel = UILabel()
    
    private var selectedRow: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Notes"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        noteCountLabel.textColor = .systemGray
        
        let flexibleSpace = UIBarButtonItem(systemItem: .flexibleSpace),
            noteCount = UIBarButtonItem(customView: noteCountLabel),
            createNoteButton = UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(createNote))
        createNoteButton.tintColor = .systemOrange
        
        toolbarItems = [flexibleSpace, noteCount, flexibleSpace, createNoteButton]
        navigationController?.isToolbarHidden = false
        
        notesDirectoryURL = getDocumentsDirectory().appending(path: "Notes/")
        
        // Create "Notes/" directory if not exists.
        do {
            try FileManager.default.createDirectory(atPath: notesDirectoryURL.path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Unable to create \"Notes/\" directory")
        }
        
        reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return noteFilenames.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let noteFilename = noteFilenames[indexPath.row],
            note = readNoteFile(noteFilename),
            paragraphs = note.components(separatedBy: "\n"),
            title = paragraphs[0]
        var subtitle = "No additional text"
        if paragraphs.count > 1 {
            subtitle = ""
            var i = 1
            while subtitle.isEmpty && i < paragraphs.count {
                subtitle = paragraphs[i]
                i += 1
            }
        }

        if let modificationDate = getModificationDateForNoteFile(noteFilename) {
            let dateFormatter = DateFormatter(),
                timeFormatter = DateFormatter(),
                dayOfWeekFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd" // 2007-01-09
            timeFormatter.dateFormat = "h:mm a" // 9:41 AM
            dayOfWeekFormatter.dateFormat = "EEEE" // Tuesday

            let secondsInAWeek = 60 * 60 * 24 * 7

            var date = dateFormatter.string(from: modificationDate)
            if date == dateFormatter.string(from: Date()) {
                // Same date -> show time.
                date = timeFormatter.string(from: modificationDate)
            } else if modificationDate.timeIntervalSinceNow * -1 < CGFloat(secondsInAWeek) {
                // Same week -> show day of week.
                date = dayOfWeekFormatter.string(from: modificationDate)
            }
            
            subtitle = "\(date)  \(subtitle)"
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = subtitle
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let noteViewController = storyboard?.instantiateViewController(withIdentifier: "Note") as? NoteViewController {
            selectedRow = indexPath.row
            noteViewController.delegate = self
            noteViewController.initialText = readNoteFile(noteFilenames[indexPath.row])
            self.currentNoteFilename = noteFilenames[indexPath.row]
            navigationController?.pushViewController(noteViewController, animated: true)
        }
    }
    
    // Swipe to delete (thanks to @TwoStraws)
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let confirmAlert = UIAlertController(title: "Delete this note?", message: "This action is irreversible.", preferredStyle: .alert)
            confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            confirmAlert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                self?.deleteNoteFile(self?.noteFilenames[indexPath.row])
                self?.noteFilenames.remove(at: indexPath.row)
                self?.tableView.deleteRows(at: [indexPath], with: .fade)
                self?.reloadData()
            })
            present(confirmAlert, animated: true)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
        }
    }
    
    // Thanks to @TwoStraws
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    @objc func createNote() {
        if let noteViewController = storyboard?.instantiateViewController(withIdentifier: "Note") as? NoteViewController {
            noteViewController.delegate = self
            navigationController?.pushViewController(noteViewController, animated: true)
            selectedRow = nil
            generateNoteFileName()
        }
    }
    
    func readNoteFile(_ filename: String) -> String {
        let fileURL = notesDirectoryURL.appending(path: "\(filename)")
        return (try? String(contentsOf: fileURL)) ?? ""
    }
    
    func deleteNoteFile(_ filename: String?) {
        if let filename = filename {
            let noteFileURL = notesDirectoryURL.appending(path: "\(filename)")
            do {
                try FileManager.default.removeItem(at: noteFileURL)
            } catch let error {
                print("Unable to remove note from disk: \(error.localizedDescription)")
            }
        }
    }
    
    func getModificationDateForNoteFile(_ filename: String) -> Date? {
        var modificationDate: Date?
        
        do {
            let noteFileURL = notesDirectoryURL.appending(path: filename),
                noteFileAttributes = try FileManager.default.attributesOfItem(atPath: noteFileURL.path())
            modificationDate = noteFileAttributes[FileAttributeKey.modificationDate] as? Date
        } catch let error {
            print("Unable to get file modification date: \(error.localizedDescription)")
        }
        
        return modificationDate
    }
    
    func loadNoteFilenames() {
        // https://stackoverflow.com/a/68533797/19227228
        if let noteURLs = try? FileManager.default.contentsOfDirectory(at: notesDirectoryURL, includingPropertiesForKeys: [.creationDateKey], options: .skipsHiddenFiles) {
            let sortedNoteURLs = noteURLs.sorted(by: {
                if let date1 = try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate,
                   let date2 = try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate {
                    return date1 > date2
                }
                return false
            })
            
            var noteFilenames: [String] = []
            for noteURL in sortedNoteURLs {
                noteFilenames.append(noteURL.lastPathComponent)
            }
            self.noteFilenames = noteFilenames
        }
    }
    
    func reloadData() {
        loadNoteFilenames()
        tableView.reloadData()
        
        // Refresh note count
        let count = noteFilenames.count
        noteCountLabel.text = "\(count) Note\(count == 1 ? "" : "s")"
    }
    
    // MARK: NoteViewControllerDelegate functions
    
    func generateNoteFileName() {
        currentNoteFilename = "\(UUID().uuidString).txt" // Will only be writen to and added to noteFilenames by saveNote() if file has text.
    }
    
    func saveNote(_ text: String) {
        if selectedRow != nil { // Updating existing note (already in table).
            noteFilenames.remove(at: selectedRow!) // Remove note so if it's added again (i.e. if there's text), it will be at the top.
        }
        
        if text.isEmpty {
            // Delete note.
            deleteNoteFile(currentNoteFilename)
        } else {
            // Write note & add to noteFilenames.
            let noteFileURL = notesDirectoryURL.appending(path: "\(currentNoteFilename)")
            do {
                // Write text to note file.
                try text.write(to: noteFileURL, atomically: true, encoding: .utf8)
            } catch let error {
                print("Unable to write note to disk: \(error.localizedDescription)")
            }
            
            noteFilenames.insert(currentNoteFilename, at: 0)
        }
        
        reloadData()
    }
    
}
