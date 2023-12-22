#!/bin/bash

setENV() {
    envAndroid=$PWD/android/fastlane/.env
    envIOS=$PWD/ios/fastlane/.env
    case $1 in
        --tester)
        changeTester $envAndroid tester-android
        changeTester $envIOS tester-ios
        ;;
        --client)
        changeTester $envAndroid client-android
        changeTester $envIOS client-ios
        ;;
    esac
}

changeTester() {
    i=1
    while read line; do

    if [[ $line == *"TESTER_GROUPS="* ]]; then
        sed -i '' "s/$line/TESTER_GROUPS=$2/g" $1
        # echo "sed -i '' 's/$line/a=999/g' $file"
    fi
    i=$((i+1))
    done < $1
}

printTutorial() {
    echo "┌────────────────────────────────────────────────────────┐"
    echo "│                     Auto Build App                     │"
    echo "├────────────────────────────────────────────────────────┤"
    echo "│      COMMAND: ./build.sh [Environment] [Tester]        │"
    echo "├───────────────┬────────────────────────────────────────┤"
    echo "│               │1.  --android                           │"
    echo "│               │2.  --dev-debug-android                 │"
    echo "│               │3.  --staging-staging-android           │"
    echo "│               │4.  --prod-release-android              │"
    echo "│               │5.  --store-android                     │"
    echo "│               │6.  --ios                               │"
    echo "│ [Environment] │7.  --dev-debug-ios                     │"
    echo "│               │8.  --staging-staging-ios               │"
    echo "│               │9.  --prod-release-ios                  │"
    echo "│               │10. --store-ios                         │"
    echo "│               │11. --dev-debug                         │"
    echo "│               │12. --staging-staging                   │"
    echo "│               │13. --prod-release                      │"
    echo "│               │14. --store                             │"
    echo "├───────────────┼────────────────────────────────────────┤"
    echo "│   [Tester]    │1.  --tester                            │"
    echo "│               │2.  --client                            │"
    echo "├───────────────┴────────────────────────────────────────┤"
    echo "│                                                        │"
    echo "│Or Please read README to learn more.                    │"
    echo "└────────────────────────────────────────────────────────┘"
}

case $2 in
    --tester)
    setENV --tester
    ;;
    --client)
    setENV --client
    ;;
    *)
        case $1 in
            --store)
            ;;
            --store-android)
            ;;
            --store-ios)
            ;;
            *)
            printTutorial
            exit 0
            ;;
        esac
    ;;
esac

case $1 in
    #build for android
    --android) # build all android
    cd android
    fastlane build_dev_debug
    fastlane build_staging_staging
    fastlane build_prod_release
    ;;
    --dev-debug-android) # build android dev-debug
    cd android
    fastlane build_dev_debug
    ;;
    --staging-staging-android) # build android staging-staging
    cd android
    fastlane build_staging_staging
    ;;
    --prod-release-android) # build android prod-release
    cd android
    fastlane build_prod_release
    ;;
    --store-android) # build store android
    cd android
    fastlane build_store
    ;;

    # build for IOS
    --ios)
    cd ios
    fastlane build_dev_debug
    fastlane build_staging_staging
    fastlane build_prod_release
    ;;
    --dev-debug-ios) # build ios dev-debug
    cd ios
    fastlane build_dev_debug
    ;;
    --staging-staging-ios) # build ios staging-staging
    cd ios
    fastlane build_staging_staging
    ;;
    --prod-release-ios)
    cd ios
    fastlane build_prod_release
    ;;
    --store-ios) # build store ios
    cd ios
    fastlane build_store
    ;;

    --dev-debug) # build dev debug for android and ios
    cd android
    fastlane build_dev_debug
    cd ..
    cd ios
    fastlane build_dev_debug
    ;;
    --staging-staging) # build prod release for android and ios
    cd android
    fastlane build_staging_staging
    cd ..
    cd ios
    fastlane build_staging_staging
    ;;
    --prod-release) # build prod release for android and ios
    cd android
    fastlane build_prod_release
    cd ..
    cd ios
    fastlane build_prod_release
    ;;

    --store)
    cd android
    fastlane build_store
    cd ../ios
    fastlane build_store
    ;;

    *)
    printTutorial
    exit 0
    ;;
esac

# reset
cd ..
setENV --tester
