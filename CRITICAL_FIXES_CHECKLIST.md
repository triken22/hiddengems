# Critical Fixes Checklist

## 🔴 CRITICAL - Must Fix Before Any Testing

- [ ] **Fix force unwrap in AppEnvironment.swift:23**
  - Replace `try!` with proper error handling for SQLiteVectorStore initialization
  - Add fallback to in-memory store if persistent store fails

- [ ] **Fix force unwrap in AppEnvironment+Preview.swift:9**
  - Same fix as above for preview environment

- [ ] **Fix force unwrap in VectorStore.swift:21**
  - Replace `.first!` with proper guard statement
  - Throw VectorStoreError if directory URL not found

- [ ] **Fix force unwraps in SyncService.swift:33**
  - Replace `components!.url!` with guard statement
  - Throw URLError(.badURL) if URL construction fails

- [ ] **Fix force unwrap in AppEnvironment.swift:86**
  - Ensure fallback URL is properly constructed
  - Consider using guard statement for safety

- [ ] **Improve fatalError in PersistenceController.swift:9,24**
  - Keep fatalError but add logging/crash reporting first
  - Consider recovery options (delete corrupted store?)

---

## 🟠 HIGH PRIORITY - Fix This Week

- [ ] **Fix race condition in SpotRepository.save() - Line 35-47**
  - Move embedding generation before Core Data save
  - Update subject only after both operations succeed
  - Add proper rollback if vector store update fails

- [ ] **Fix race condition in SpotRepository subject access - Line 42,57**
  - Move subject.send() outside of context.perform block
  - Ensure thread-safe access to subject.value

- [ ] **Fix GroupRepository.joinGroup logic**
  - Should call API to join group, not search local database
  - Add proper sync after joining

- [ ] **Fix duplicate GroupListViewModel creation**
  - Remove creation in HomeViewModel
  - Pass instance from AppEnvironment instead

- [ ] **Fix unstructured Task in repository init**
  - Add explicit loadData() method
  - Or make factory method that waits for loading

- [ ] **Fix alert binding in QuickAddView.swift:68**
  - Replace Binding.constant() with proper two-way binding
  - Allow user to dismiss error alerts

- [ ] **Fix save button in QuickAddView.swift:59**
  - Only dismiss if save succeeds
  - Return success/failure from save() method

- [ ] **Add timeout to LocationService**
  - Add 10-second timeout
  - Resume continuation with nil if timeout occurs

---

## 🟡 MEDIUM PRIORITY - Fix Before Production

- [ ] **Optimize array operations in SpotRepository.save()**
  - Replace filter + append + sort with more efficient updates
  - Consider using sorted insert or dictionary lookup

- [ ] **Add cancellation cleanup to LocationService**
  - Cancel previous requests before starting new one
  - Prevent continuation overwrites

- [ ] **Add sync status feedback to users**
  - Expose SyncStatus as @Published property
  - Show UI indicators for sync state

- [ ] **Add pagination to spot loading**
  - Don't load all spots at once
  - Implement fetchLimit and lazy loading

- [ ] **Store sensitive keys in Keychain**
  - Move OPENAI_API_KEY to Keychain
  - Move APP_SYNC_TOKEN to Keychain
  - Add KeychainHelper utility

- [ ] **Add input validation**
  - Validate group name length
  - Validate spot title length
  - Validate coordinate ranges

---

## 🔵 LOW PRIORITY - Future Improvements

- [ ] **Add documentation comments**
  - Document all public methods
  - Add parameter and return descriptions
  - Document thread safety requirements

- [ ] **Extract magic numbers to constants**
  - AIJobQueue delays
  - Coordinate spans
  - UI dimensions

- [ ] **Improve test coverage**
  - Add ViewModel tests
  - Add Repository tests
  - Add integration tests
  - Target: >60% code coverage

- [ ] **Add missing functionality**
  - Spot detail view
  - Edit spot feature
  - Delete group feature
  - Image upload to cloud storage
  - Semantic search UI

---

## 🔐 Security Improvements

- [ ] Move API keys to Keychain (not environment variables)
- [ ] Add rate limiting to Cloudflare Worker
- [ ] Add input validation in Worker
- [ ] Implement user authentication
- [ ] Add request signing for API calls

---

## 🚀 Performance Improvements

- [ ] Add pagination to sync/pull endpoint
- [ ] Use background contexts for heavy Core Data operations  
- [ ] Optimize vector search (use ANN algorithms)
- [ ] Add caching layer for frequently accessed data
- [ ] Lazy load images on map

---

## 📝 Testing TODO

- [ ] Add unit tests for ViewModels (HomeViewModel, QuickAddViewModel, GroupListViewModel)
- [ ] Add unit tests for Repositories (SpotRepository, GroupRepository)
- [ ] Add tests for SyncCoordinator
- [ ] Add tests for AIJobQueue retry logic
- [ ] Add integration tests for sync flow
- [ ] Add UI tests for critical user flows

---

## Estimated Time

- **Critical Fixes:** 2-3 hours
- **High Priority:** 5-7 hours  
- **Medium Priority:** 6-8 hours
- **Low Priority:** 10-15 hours
- **Total:** 23-33 hours

---

## Next Steps

1. Start with critical fixes (can be done in 2-3 hours)
2. Run the app and verify no crashes
3. Move to high priority fixes
4. Add tests alongside each fix
5. Set up CI/CD to prevent regressions
