class Corporation < Party
  validates :corporate_number, presence: true
end
