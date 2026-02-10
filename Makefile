
run:
	swift run NowCoinerApp

icon:
	./scripts/generate_app_icon.sh "$(SOURCE)" Sources/NowCoinerApp/Resources

.PHONY: run icon
