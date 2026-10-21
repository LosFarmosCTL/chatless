import Emotes
import SwiftUI

struct EmoteTextAttribute: TextAttribute {
  let keys: [EmoteRenderKey?]
  let definition: EmoteDefinition
}
