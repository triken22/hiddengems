import CoreData

extension Setting {
    init(entity: SettingEntity) {
        self.id = entity.id ?? ""
        self.value = (entity.value as? Data) ?? Data()
    }
}

extension SettingEntity {
    func update(from setting: Setting) {
        id = setting.id
        value = setting.value as NSObject?
    }
}
