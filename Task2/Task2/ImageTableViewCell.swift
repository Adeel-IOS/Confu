//
//  ImageTableViewCell.swift
//  Task2
//
//  Created by Adeel Hussain on 28/02/2022.
//

import UIKit

class ImageTableViewCell: UITableViewCell {

    @IBOutlet weak var imgView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
